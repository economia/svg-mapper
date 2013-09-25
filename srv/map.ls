require! {
    canvg
    Canvas:canvas
    fs
    $ : jquery
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
$exportables = $content.find "[data-export]"
$exportables.each ->
    $ele = $ @
    exportable = $ele.attr \data-export
    index = getExportableIndex exportable
    color = getColor index
    $ele.attr \fill color

str = $content.html!
str .= replace "![CDATA[" "<![CDATA["
width = 1858 * 2
height = 995 * 2

opts =
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes
canvas = new Canvas width, height
canvg canvas, str, opts
buf = canvas.toBuffer!
<~ fs.writeFile "#__dirname/../test.png", buf
console.log 'done'
process.exit!
