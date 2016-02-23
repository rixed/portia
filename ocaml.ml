# 302 "definitions.fw"
let linenum lineno fname =
    Printf.sprintf "# %d \"%s\"\n" (lineno+1) fname

let () = PortiaConfig.linenum := linenum
