/*var projection = ol.proj.get('EPSG:4326');
var projectionExtent = projection.getExtent();
*/

function init(){

var map = L.map('map').setView([37.7, -122.4], 10);
map.options.maxZoom = 15;map.options.minZoom = 10
var toner = new L.StamenTileLayer("toner");
var osm = new L.TileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png');
var bing = new L.BingLayer("Ak9B0icHsz6Z-MEMGpXFxHjFA6liDJYmv2JNiddSzwIK5krb37s03SwekohbbNOs");

map.addLayer(toner);
map.addLayer(bing);

var maxfar = L.tileLayer('http://s3-us-west-2.amazonaws.com/landuse/zoning/effective_max_far/{z}/{x}/{y}.png',{tms: true, opacity:0.7}).addTo(map);
var maxdua = L.tileLayer('http://s3-us-west-2.amazonaws.com/landuse/zoning/effective_max_dua/{z}/{x}/{y}.png',{tms: true, opacity:0.4}).addTo(map);

/*document.getElementById('bing').onclick = function () {
    var enable = this.className !== 'active';
    bing.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};*/

document.getElementById('toner').onclick = function () {
    var enable = this.className !== 'active';
    toner.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};

document.getElementById('maxdua_light').onclick = function () {
    var enable = this.className !== 'active';
    maxdua.setOpacity(enable ? 0.3 : 0);
    this.className = enable ? 'active' : '';
    document.getElementById('maxdua_heavy').className = '';
    return false;
};

document.getElementById('maxdua_heavy').onclick = function () {
    var enable = this.className !== 'active';
    maxdua.setOpacity(enable ? 0.7 : 0);
    this.className = enable ? 'active' : '';
    document.getElementById('maxdua_light').className = '';
    return false;
};

document.getElementById('maxfar_light').onclick = function () {
    var enable = this.className !== 'active';
    maxfar.setOpacity(enable ? 0.3 : 0);
    this.className = enable ? 'active' : '';
    document.getElementById('maxfar_heavy').className = '';
    return false;
};

document.getElementById('maxfar_heavy').onclick = function () {
    var enable = this.className !== 'active';
    maxfar.setOpacity(enable ? 0.7 : 0);
    this.className = enable ? 'active' : '';
    document.getElementById('maxfar_light').className = '';
    return false;
};


/*var zoning_wms = L.tileLayer.wms("http://10.1.1.204:8080/geoserver/gwc/service/wms?", {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:all_colors',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
});
zoning_wms.addTo(map);*/


/*
var mixedemployment = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:me-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var maxfar = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:mt-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var mixedresidential = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:mr-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var retailbigbox = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:rb-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var retailstripmall = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:rs-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var office = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:of-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var singlefamilydetached = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:hs-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);

var singlefamilyattached = L.tileLayer.wms('http://10.1.1.204:8080/geoserver/gwc/service/wms?', {
    layers: 'mtc:all_codes_colors',
    styles: 'mtc:ht-t',
    format: 'image/png',
    transparent: true,
    version: '1.1.0',
    attribution: "MTC"
}).addTo(map);
*/
// Layer switcher


/*
document.getElementById('singlefamilydetached').onclick = function () {
    var enable = this.className !== 'active';
    singlefamilydetached.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};

document.getElementById('retailstripmall').onclick = function () {
    var enable = this.className !== 'active';
    retailstripmall.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};

document.getElementById('retailbigbox').onclick = function () {
    var enable = this.className !== 'active';
    retailbigbox.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};

document.getElementById('office').onclick = function () {
    var enable = this.className !== 'active';
    office.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};

document.getElementById('singlefamilyattached').onclick = function () {
    var enable = this.className !== 'active';
    singlefamilyattached.setOpacity(enable ? 1 : 0);
    this.className = enable ? 'active' : '';
    return false;
};


*/

}
