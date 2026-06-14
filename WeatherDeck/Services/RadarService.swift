import Foundation

/// Generates self-contained HTML for interactive animated radar via RainViewer + Leaflet.
enum RadarService {

    static func stationLoopURL(_ station: String) -> URL? {
        URL(string: "https://radar.weather.gov/ridge/standard/\(station.uppercased())_loop.gif")
    }

    /// Interactive animated radar centered on a lat/lon. Rendered in WKWebView.
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
          .ctrl{position:absolute;z-index:1000;bottom:12px;left:12px;background:rgba(15,20,28,.85);
                color:#cfe3ff;padding:8px 12px;border-radius:8px;font:13px -apple-system,system-ui;}
          .ctrl button{background:#1d6fe0;color:#fff;border:0;border-radius:5px;padding:6px 12px;
                       cursor:pointer;margin-left:6px;font-size:13px;}
          .ts{font-variant-numeric:tabular-nums;}
        </style>
        </head>
        <body>
        <div id="map"></div>
        <div class="ctrl">
          <span class="ts" id="ts">loading radar…</span>
          <button id="play">⏸</button>
        </div>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <script>
          const map = L.map('map',{zoomControl:false,attributionControl:false})
                       .setView([\(lat), \(lon)], \(zoom));
          L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',{maxZoom:19}).addTo(map);
          L.circleMarker([\(lat), \(lon)],{radius:6,color:'#1d6fe0',fillOpacity:0.9,weight:2}).addTo(map);

          let frames=[], idx=0, layers={}, timer=null, playing=true;
          const tsEl=document.getElementById('ts');

          function showFrame(i){
            if(!frames.length) return;
            const f=frames[i];
            if(!layers[f.path]){
              layers[f.path]=L.tileLayer(
                `https://tilecache.rainviewer.com${f.path}/256/{z}/{x}/{y}/4/1_1.png`,
                {opacity:0,zIndex:f.time});
              layers[f.path].addTo(map);
            }
            Object.values(layers).forEach(l=>l.setOpacity(0));
            layers[f.path].setOpacity(0.75);
            const d=new Date(f.time*1000);
            tsEl.textContent=d.toLocaleTimeString([],{hour:'numeric',minute:'2-digit'});
          }

          function animate(){
            idx=(idx+1)%frames.length;
            showFrame(idx);
          }

          fetch('https://api.rainviewer.com/public/weather-maps.json')
            .then(r=>r.json())
            .then(data=>{
              const past=(data.radar&&data.radar.past)||[];
              const now=(data.radar&&data.radar.nowcast)||[];
              frames=past.concat(now);
              if(frames.length){
                showFrame(frames.length-1);
                idx=frames.length-1;
                timer=setInterval(()=>{ if(playing) animate(); },600);
              } else { tsEl.textContent='no radar data'; }
            })
            .catch(()=>{ tsEl.textContent='radar load error'; });

          document.getElementById('play').onclick=function(){
            playing=!playing;
            this.textContent=playing?'⏸':'▶';
          };
        </script>
        </body>
        </html>
        """
    }
}
