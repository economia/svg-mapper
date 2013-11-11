require! {
    zlib
    async
    canvg
    Canvas:canvas
    fs
    jsdom.jsdom
    optimist
    $ : jquery
    './TileMaker'
    './TileJsonGenerator'
}
optimist
    .usage "Usage: $0 -f [filename] -z [num]"
    .demand ["f" "z"]
    .describe "f" "SVG file to use"
    .describe "z" "Zoom level to generate"
argv = optimist.argv
global.document = jsdom "<html><head></head><body>hello world</body></html>"
global.window = global.document.parentWindow
global.navigator = {userAgent: "webkit"}
require! L: leaflet

fixCdata = (str) ->
    str.replace "![CDATA[" "<![CDATA["

existingDirs = {}
filename = argv.f
zoomLevel = argv.z
tileJsonGenerator = new TileJsonGenerator
dirname = filename.replace /\.svg$/i ""
(err, content) <~ fs.readFile "#filename"
(err) <~ fs.mkdir "#dirname"
console.log "Starting #filename"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "style" .remove!

originalImage = fixCdata $content.html!

$exportables = $content.find "[data-export]"
$exportables.each ->
    $ele = $ @
    exportable = $ele.attr \data-export
    index = tileJsonGenerator.getExportableIndex exportable
    color = tileJsonGenerator.getColorByIndex index
    $ele.attr \fill color

contouredExportsImage = fixCdata $content.html!
console.log "#zoomLevel: start"
bounds = $content.find "svg" .attr \data-bounds
if not bounds
    console.error "No data-bounds attribute found in SVG file (should be north,west,south,east)"
    process.exit!

[north, west, south, east] = bounds.split /[, ;]/g .map -> parseFloat it

{x:x0, y:y0} = L.CRS.EPSG3857.latLngToPoint do
    new L.LatLng north, west
    zoomLevel
{x:x1, y:y1} = L.CRS.EPSG3857.latLngToPoint do
    new L.LatLng south, east
    zoomLevel

offsetX = x0 % 256
offsetY = y0 % 256
width   = Math.abs x0 - x1
height  = Math.abs y0 - y1
# targetWidth = 1500
# scale = targetWidth / width
# width *= scale
# height *= scale
tileCountOffsetX = Math.floor x0 / 256
tileCountOffsetY = Math.floor y0 / 256

opts =
    offsetX: offsetX
    offsetY: offsetY
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes

createImages = (svg, cb) ->
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, opts
    # <~ fs.writeFile "#{filename}.png", canvas.toBuffer!
    # return cb!
    tilesDone = 0
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileCountOffsetX
            y += tileCountOffsetY
            buffer = canvas.toBuffer!
            if not existingDirs["#dirname/#z"]
                fs.mkdirSync "#dirname/#z"
                existingDirs["#dirname/#z"] := true
            if not existingDirs["#dirname/#z/#x"]
                fs.mkdirSync "#dirname/#z/#x"
                existingDirs["#dirname/#z/#x"] := true
            <~ fs.writeFile "#dirname/#z/#x/#y.png", buffer
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!


createJsons = (svg, cb) ->
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, opts
    tilesDone = 0
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileCountOffsetX
            y += tileCountOffsetY
            tjson = tileJsonGenerator.generateJson canvas
            data = JSON.stringify tjson
            <~ fs.writeFile "#dirname/#z/#x/#y.json", data
            (err, compressed) <~ zlib.gzip data
            <~ fs.writeFile "#dirname/#z/#x/#y.json.gz", compressed
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!

console.log "#zoomLevel: tiles"
<~ createImages originalImage
console.log "#zoomLevel: JSON"
<~ createJsons contouredExportsImage
console.log "#zoomLevel: done"
console.log "All done, cooling down..."
setTimeout process.exit, 2000
