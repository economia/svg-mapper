require! {
    "./utils"
    optimist
}
optimist
    .usage "Usage: $0 -f [file] -d [dir]"
    .demand <[f d]>
    .describe "f" "SVG file for which to generate metadata"
    .describe "d" "Directory to which save the metadata"

{argv} = optimist
utils.generateMetadata argv.f, argv.d
