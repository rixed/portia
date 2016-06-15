# 353 "definitions.fw"
let linenum lineno fname =
    Printf.sprintf "#line %d \"%s\"\n" (lineno+1) fname

let () = PortiaConfig.linenum := linenum
