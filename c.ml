
# 300 "definitions.fw"
let linenum lineno fname =
    Printf.sprintf "#line %d \"%s\"" (lineno+1) fname

let () = PortiaConfig.linenum := linenum
