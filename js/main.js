/*var projection = ol.proj.get('EPSG:4326');
var projectionExtent = projection.getExtent();
*/

function init(){

var map = L.map('map').setView([37.7, -122.4], 11);

// replace "toner" here with "terrain" or "watercolor"
var layer = new L.StamenTileLayer("toner");
map.addLayer(layer);

var zoning_wms = L.tileLayer.wms("http://10.1.1.204:8081/geoserver/gwc/service/wms?", {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:all_colors',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
});
zoning_wms.addTo(map);
}

