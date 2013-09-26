require! {
    canvg
    Canvas:canvas
    fs
    $ : jquery
    './TileMaker'
}
exportables = []
getExportableIndex = (str) ->
    index = exportables.indexOf str
    if index != -1
        return index
    length = exportables.push str
    return length - 1

getColor = (index) ->
    index *= 5
    color = index.toString 16
    while color.length < 6
        color = "0" + color
    "#" + color

(err, content) <~ fs.readFile "#__dirname/../data/map.svg"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "style" .remove!
# $exportables = $content.find "[data-export]"
# $exportables.each ->
#     $ele = $ @
#     exportable = $ele.attr \data-export
#     index = getExportableIndex exportable
#     color = getColor index
#     $ele.attr \fill color

str = $content.html!
str .= replace "![CDATA[" "<![CDATA["
width = 1858 * 16
height = 995 * 16

opts =
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes
canvas = new Canvas width, height
canvg canvas, str, opts
buf = canvas.toBuffer!
tileMaker = new TileMaker canvas, 256, 256, 7
    ..on \tile (z, x, y, buffer) ->
        <~ fs.mkdir "#__dirname/../data/tiles/#z"
        <~ fs.mkdir "#__dirname/../data/tiles/#z/#x"
        fs.writeFile "#__dirname/../data/tiles/#z/#x/#y.png", buffer

    ..makeTiles!
# <~ fs.writeFile "#__dirname/../test.png", buf
console.log 'done'
setTimeout process.exit, 8000
