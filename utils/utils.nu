export def validate_arg [
    arg: any, # The arg to validate
    arg_name: string, # The name of the argument
    span: record # The span to make an error on if this argument is invalid
    ...options # The valid options.  If one of these don't match, make an error
] {
    if $arg == null {
        let options = $options | each {|i| $"'($i)'"} | str join ,;
        error make {
            msg: $"Missing required argument '($arg_name)'. Possible values ($options)", 
            label: {
                text: $"Pass the required argument '($arg_name)' with one of the following options: ($options)", 
                span: $span 
            } 
        }
    }

    if $arg not-in $options {
        let options = $options | each {|i| $"'($i)'"} | str join ,;
        error make {
            msg: $"Invalid value '($arg)'. Possible values ($options)", 
            label: {
                text: $"Change to one of the possible values: ($options)", 
                span: $span 
            } 
        }
    }
}