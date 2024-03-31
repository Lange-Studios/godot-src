# Builds the godot template for android
def "main build android-template" [
  --skip-cs-glue # Skips generating the csharp glue code
  --release # Optimizes with release settings
  --debug # optimizes with debug settings
  --custom-modules: string, # A csv seperated list of additional modules to include in the template
] {
    if $skip_cs_glue {
        print "received skip-cs flag!"
    }

    print $env.FILE_PWD
    print $nu.os-info.name

    if $nu.os-info.name == "linux" {
        print "I'm linux!"
    }

    for i in 0..5 {
        print ("i is: " + ($i | into string))
    }

    for file in (ls .) {
        print ("file is: " + $file.name)
    }
}
