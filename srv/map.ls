require! {
    canvg
    Canvas:canvas
    fs
    $ : jquery
}
(err, content) <~ fs.readFile "#__dirname/../data/map.svg"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "svg"
    # ..attr \width 1858 * 2
    # ..attr \height 995 * 2
    # ..attr \viewBox "0 0 929 497"
str = $content.html!
str .= replace "![CDATA[" "<![CDATA["

width = 1858 * 8
height = 995 * 8

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
