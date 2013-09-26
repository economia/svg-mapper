require! {
    canvg
    Canvas:canvas
    fs
    $ : jquery
    './TileMaker'
    './TileJsonGenerator'
}
fixCdata = (str) ->
    str.replace "![CDATA[" "<![CDATA["

tileJsonGenerator = new TileJsonGenerator
(err, content) <~ fs.readFile "#__dirname/../data/map.svg"
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

zoomLevel = 5
width = 1858 * Math.pow 2, (zoomLevel - 3)
height = 995 * Math.pow 2, (zoomLevel - 3)

opts =
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes

createImages = (svg, cb) ->
    canvas = new Canvas width, height
    canvg canvas, svg, opts
    tilesDone = 0
    tileMaker = new TileMaker canvas, 256, 256, zoomLevel
        ..on \tile (z, x, y, canvas) ->
            buffer = canvas.toBuffer!
            <~ fs.mkdir "#__dirname/../data/tiles/#z"
            <~ fs.mkdir "#__dirname/../data/tiles/#z/#x"
            <~ fs.writeFile "#__dirname/../data/tiles/#z/#x/#y.png", buffer
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!

    #<~ fs.writeFile "#__dirname/../test.png", canvas.toBuffer!

createJsons = (svg, cb) ->
    canvas = new Canvas width, height
    canvg canvas, svg, opts
    tilesDone = 0
    tileMaker = new TileMaker canvas, 256, 256, zoomLevel
        ..on \tile (z, x, y, canvas) ->
            tjson = tileJsonGenerator.generateJson canvas
            <~ fs.writeFile "#__dirname/../data/tiles/#z/#x/#y.json", JSON.stringify tjson, null, "  "
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!


<~ createImages originalImage
<~ createJsons contouredExportsImage
console.log "Cooling down..."
setTimeout process.exit, 1000
