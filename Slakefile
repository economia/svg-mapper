require! {
    fs
    child_process.exec
}
task \build ->
    (err, result) <~ exec "lsc -o #__dirname/bin -c #__dirname/src"
    console.error err if err
    (err, data) <~ fs.readFile "#__dirname/bin/cli.js"
    cliFile = data.toString!
    cliFileWithHeader = "#!/usr/bin/env node" + "\n\n" + data
    fs.writeFile "#__dirname/bin/cli.js" cliFileWithHeader


