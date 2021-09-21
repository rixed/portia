
# 288 "definitions.fw"
let linenum lineno fname =
    Printf.sprintf "# %d \"%s\"" (lineno+1) fname

let () = PortiaConfig.linenum := linenum
