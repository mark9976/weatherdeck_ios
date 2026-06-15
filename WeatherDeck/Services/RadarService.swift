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
          .ctrl button.active{background:#2d8fff;}
          .ctrl button.off{background:#333a44;color:#8aa0b8;}
          .ts{font-variant-numeric:tabular-nums;}
          .mode-sw{position:absolute;z-index:1000;top:12px;right:12px;display:flex;gap:6px;}
          .mode-sw button{background:rgba(15,20,28,.92);color:#8aa0b8;border:1px solid #2a3545;
                          border-radius:8px;padding:6px 12px;font-size:12px;cursor:pointer;}
          .mode-sw button.active{color:#fff;border-color:#1d6fe0;background:rgba(29,111,224,.3);}
        </style>
        </head>
        <body>
        <div id="map"></div>
        <div class="mode-sw">
          <button id="btn-live" class="active" onclick="setMode('live')">Live</button>
          <button id="btn-anim" onclick="setMode('anim')">Animated</button>
        </div>
        <div class="ctrl">
          <span class="ts" id="ts">loading radar...</span>
          <button id="play" style="display:none;">&#9208;</button>
        </div>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script>
          const LAT=\(lat), LON=\(lon);
          const map=L.map('map',{zoomControl:false,attributionControl:false,
                                  minZoom:4, maxZoom:13}).setView([LAT,LON],\(zoom));

          L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      {maxZoom:19}).addTo(map);

          L.circleMarker([LAT,LON],{radius:6,color:'#1d6fe0',fillOpacity:0.9,weight:2}).addTo(map);

          const tsEl=document.getElementById('ts');
          const playBtn=document.getElementById('play');
          let mode='live', nexradLayer=null, rvFrames=[], rvIdx=0, rvLayers={}, rvTimer=null, rvPlaying=true;

          // --- NEXRAD live tiles (Iowa State Mesonet) ---
          function showNexrad(){
            clearRV();
            if(nexradLayer){nexradLayer.remove()}
            nexradLayer=L.tileLayer(
              'https://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/nexrad-n0q-900913/{z}/{x}/{y}.png',
              {opacity:0.7, maxZoom:13, tileSize:256, zIndex:100,
               attribution:'Iowa State Mesonet NEXRAD'});
            nexradLayer.addTo(map);
            const now=new Date();
            tsEl.textContent='Live radar '+now.toLocaleTimeString([],{hour:'numeric',minute:'2-digit'});
            playBtn.style.display='none';
          }

          // --- RainViewer animated ---
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
                  rvIdx=rvFrames.length-1;
                  showRVFrame(rvIdx);
                  rvTimer=setInterval(()=>{
                    if(rvPlaying){rvIdx=(rvIdx+1)%rvFrames.length;showRVFrame(rvIdx)}
                  },600);
                } else {tsEl.textContent='no animation data'}
              })
              .catch(()=>{tsEl.textContent='animation load error'});
          }

          // --- Mode switching ---
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

          showNexrad();
        </script>
        </body>
        </html>
        """
    }
}