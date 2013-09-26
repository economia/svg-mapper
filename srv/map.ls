require! {
    canvg
    Canvas:canvas
    fs
    $ : jquery
    './TileMaker'
    './TileJsonGenerator'
}

tileJsonGenerator = new TileJsonGenerator

(err, content) <~ fs.readFile "#__dirname/../data/map.svg"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "style" .remove!
$exportables = $content.find "[data-export]"
$exportables.each ->
    $ele = $ @
    exportable = $ele.attr \data-export
    index = tileJsonGenerator.getExportableIndex exportable
    color = tileJsonGenerator.getColorByIndex index
    $ele.attr \fill color
console.log \bar tileJsonGenerator.getColorByIndex 2532
str = $content.html!
str .= replace "![CDATA[" "<![CDATA["
width = 1858 * 0.5
height = 995 * 0.5

opts =
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes
canvas = new Canvas width, height
canvg canvas, str, opts
buf = canvas.toBuffer!
tileMaker = new TileMaker canvas, 256, 256, 2
    ..on \tile (z, x, y, canvas) ->
        tjson = tileJsonGenerator.generateJson canvas
        buffer = canvas.toBuffer!
        <~ fs.mkdir "#__dirname/../data/tiles/#z"
        <~ fs.mkdir "#__dirname/../data/tiles/#z/#x"
        fs.writeFile "#__dirname/../data/tiles/#z/#x/#y.png", buffer
        fs.writeFile "#__dirname/../data/tiles/#z/#x/#y.json", JSON.stringify tjson, null, "  "

    ..makeTiles!
<~ fs.writeFile "#__dirname/../test.png", buf
console.log 'done'
setTimeout process.exit, 8000
