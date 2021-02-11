
# 288 "definitions.fw"
let linenum lineno fname =
    Printf.sprintf "# %d %S" (lineno+1) fname

let () = PortiaConfig.linenum := linenum
