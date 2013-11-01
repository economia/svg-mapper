require! {
    fs
    child_process.exec
    async
}
(err, files) <~ fs.readdir "#__dirname/../data/"
files .= filter -> /svg$/.test it
files .= map -> it.replace ".svg" ""

console.log "Go!"
<~ async.eachLimit files, 2, (file, cb) ->
    console.log "Starting #file"
    <~ async.eachLimit [10 to 6], 4, (zoomLevel, cb) ->
        console.log "Starting #file #zoomLevel"
        (err, stdout, stderr) <~ exec "lsc #__dirname/map.ls -f #file -z #zoomLevel"
        console.log err if err
        console.log stderr if stderr
        console.log "Done #file - #zoomLevel"
        cb!
    console.log "Done #file - all"
    <~ fs.rename "#__dirname/../data/#file.svg", "#__dirname/../data/done/#file.svg"
    cb!

console.log "Done!"
