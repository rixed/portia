# 27 "config.fw"
let find_definitions =
    ref ((fun _txt -> []) : string -> (string * bool * int * int) list)
let find_references =
    ref ((fun _txt -> []) : string -> (string * int * int) list)
let find_inclusions =
    ref ((fun _txt -> []) : string -> string list)
let postprocess =
    ref ((fun txt -> txt) : string -> string)
let linenum =
    ref ((fun _n _f -> "") : int -> string -> string)
