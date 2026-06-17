import Foundation

enum RadarService {

    static func stationLoopURL(_ station: String) -> URL? {
        URL(string: "https://radar.weather.gov/ridge/standard/\(station.uppercased())_loop.gif")
    }

    static func interactiveHTML(lat: Double, lon: Double, zoom: Int = 8) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no"/>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
        <style>
          html,body,#map{height:100%;margin:0;background:#0b0f14;}
          .ctrl{position:absolute;z-index:1000;bottom:12px;left:12px;background:rgba(15,20,28,.92);
                color:#cfe3ff;padding:10px 14px;border-radius:10px;font:13px -apple-system,system-ui;
                display:flex;gap:10px;align-items:center;}
          .ctrl button{background:#1d6fe0;color:#fff;border:0;border-radius:6px;padding:6px 12px;
                       cursor:pointer;font-size:13px;}
          .mode-sw{position:absolute;z-index:1000;top:12px;right:12px;display:flex;gap:6px;flex-wrap:wrap;max-width:200px;justify-content:flex-end;}
          .mode-sw button{background:rgba(15,20,28,.92);color:#8aa0b8;border:1px solid #2a3545;
                          border-radius:8px;padding:6px 10px;font-size:11px;cursor:pointer;}
          .mode-sw button.active{color:#fff;border-color:#1d6fe0;background:rgba(29,111,224,.3);}
          .wind-label{background:rgba(15,20,28,.8);color:#e0a21d;padding:1px 4px;border-radius:3px;
                      font:bold 10px -apple-system;white-space:nowrap;border:1px solid rgba(224,162,29,.4);}
        </style>
        </head>
        <body>
        <div id="map"></div>
        <div class="mode-sw">
          <button id="btn-live" class="active" onclick="setMode('live')">Live</button>
          <button id="btn-anim" onclick="setMode('anim')">Animated</button>
          <button id="btn-wind" onclick="toggleWind()">🌬 Wind</button>
        </div>
        <div class="ctrl">
          <span id="ts">loading radar...</span>
          <button id="play" style="display:none;">&#9208;</button>
        </div>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script>
          const LAT=\(lat), LON=\(lon);
          const map=L.map('map',{zoomControl:false,attributionControl:false,
                                  minZoom:4,maxZoom:13}).setView([LAT,LON],\(zoom));

          L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      {maxZoom:19}).addTo(map);
          L.circleMarker([LAT,LON],{radius:6,color:'#1d6fe0',fillOpacity:0.9,weight:2}).addTo(map);

          const tsEl=document.getElementById('ts');
          const playBtn=document.getElementById('play');
          let mode='live',nexradLayer=null,rvFrames=[],rvIdx=0,rvLayers={},rvTimer=null,rvPlaying=true;
          let windVisible=false,windMarkers=[];

          // --- NEXRAD ---
          function showNexrad(){
            clearRV();
            if(nexradLayer) nexradLayer.remove();
            nexradLayer=L.tileLayer(
              'https://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/nexrad-n0q-900913/{z}/{x}/{y}.png',
              {opacity:0.7,maxZoom:13,tileSize:256,zIndex:100});
            nexradLayer.addTo(map);
            tsEl.textContent='Live radar '+new Date().toLocaleTimeString([],{hour:'numeric',minute:'2-digit'});
            playBtn.style.display='none';
          }

          // --- RainViewer ---
          function clearRV(){
            if(rvTimer){clearInterval(rvTimer);rvTimer=null}
            Object.values(rvLayers).forEach(l=>l.remove());
            rvLayers={};rvFrames=[];rvIdx=0;
          }
          function showRVFrame(i){
            if(!rvFrames.length)return;
            const f=rvFrames[i];
            if(!rvLayers[f.path]){
              rvLayers[f.path]=L.tileLayer(
                'https://tilecache.rainviewer.com'+f.path+'/256/{z}/{x}/{y}/4/1_1.png',
                {opacity:0,zIndex:200,maxZoom:12});
              rvLayers[f.path].addTo(map);
            }
            Object.values(rvLayers).forEach(l=>l.setOpacity(0));
            rvLayers[f.path].setOpacity(0.75);
            tsEl.textContent=new Date(f.time*1000).toLocaleTimeString([],{hour:'numeric',minute:'2-digit'});
          }
          function startRV(){
            if(nexradLayer){nexradLayer.remove();nexradLayer=null}
            clearRV();
            playBtn.style.display='inline-block';
            tsEl.textContent='loading animation...';
            fetch('https://api.rainviewer.com/public/weather-maps.json')
              .then(r=>r.json())
              .then(d=>{
                rvFrames=(d.radar?.past||[]).concat(d.radar?.nowcast||[]);
                if(rvFrames.length){
                  rvIdx=rvFrames.length-1;showRVFrame(rvIdx);
                  rvTimer=setInterval(()=>{if(rvPlaying){rvIdx=(rvIdx+1)%rvFrames.length;showRVFrame(rvIdx)}},600);
                }else tsEl.textContent='no data';
              }).catch(()=>tsEl.textContent='error');
          }

          function setMode(m){
            mode=m;
            document.getElementById('btn-live').className=m==='live'?'active':'';
            document.getElementById('btn-anim').className=m==='anim'?'active':'';
            if(m==='live') showNexrad(); else startRV();
          }

          playBtn.onclick=function(){
            rvPlaying=!rvPlaying;
            this.innerHTML=rvPlaying?'&#9208;':'&#9654;';
          };

          // --- Wind arrows from NWS observation stations ---
          function toggleWind(){
            const btn=document.getElementById('btn-wind');
            windVisible=!windVisible;
            btn.className=windVisible?'active':'';
            if(windVisible) loadWind(); else clearWind();
          }

          function clearWind(){
            windMarkers.forEach(m=>m.remove());
            windMarkers=[];
          }

          function loadWind(){
            clearWind();
            const bounds=map.getBounds();
            // NWS doesn't have a bbox station query, so we use the observation stations
            // for the current grid point. We fetch from api.weather.gov.
            fetch(`https://api.weather.gov/stations?limit=30&state=`,{
              headers:{'User-Agent':'RawWeather/1.0','Accept':'application/geo+json'}
            })
            .catch(()=>null);

            // Simpler approach: use the points-based stations URL
            fetch(`https://api.weather.gov/points/${LAT.toFixed(4)},${LON.toFixed(4)}`,{
              headers:{'User-Agent':'RawWeather/1.0','Accept':'application/geo+json'}
            })
            .then(r=>r.json())
            .then(d=>{
              if(!d.properties?.observationStations) return;
              return fetch(d.properties.observationStations,{
                headers:{'User-Agent':'RawWeather/1.0','Accept':'application/geo+json'}
              });
            })
            .then(r=>r?.json())
            .then(d=>{
              if(!d?.features) return;
              const stationIds=d.features.slice(0,15).map(f=>f.properties?.stationIdentifier).filter(Boolean);
              stationIds.forEach(id=>{
                fetch(`https://api.weather.gov/stations/${id}/observations/latest?require_qc=false`,{
                  headers:{'User-Agent':'RawWeather/1.0','Accept':'application/geo+json'}
                })
                .then(r=>r.json())
                .then(obs=>{
                  if(!obs?.geometry?.coordinates) return;
                  const [lng,lat]=obs.geometry.coordinates;
                  const p=obs.properties;
                  if(!p) return;
                  const ws=p.windSpeed?.value;
                  const wd=p.windDirection?.value;
                  if(ws==null||wd==null) return;

                  const mph=(p.windSpeed?.unitCode?.includes('km_h')?ws*0.621:ws*2.237);
                  const dir=['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'];
                  let di=Math.round(wd/22.5)%16; if(di<0)di+=16;

                  // Create wind arrow marker
                  const arrowSvg=`<svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
                    <g transform="rotate(${wd+180},20,20)">
                      <line x1="20" y1="6" x2="20" y2="34" stroke="#e0a21d" stroke-width="2"/>
                      <polygon points="20,4 15,14 25,14" fill="#e0a21d"/>
                    </g>
                  </svg>`;

                  const icon=L.divIcon({
                    html:arrowSvg+`<div class="wind-label">${Math.round(mph)}</div>`,
                    className:'',
                    iconSize:[40,55],
                    iconAnchor:[20,20]
                  });

                  const marker=L.marker([lat,lng],{icon:icon,zIndexOffset:500})
                    .bindPopup(`<b>${id}</b><br>${Math.round(mph)} mph ${dir[di]}<br>Gusts: ${p.windGust?.value!=null?Math.round(p.windGust.value*2.237)+' mph':'--'}`)
                    .addTo(map);
                  windMarkers.push(marker);
                })
                .catch(()=>{});
              });
            })
            .catch(()=>{});
          }

          showNexrad();
        </script>
        </body>
        </html>
        """
    }
}
