
# 105 "main.fw"
open Batteries


# 51 "main.fw"
let rec load_lib libdir fname =
    match libdir with
    | [] ->
        failwith ("Cannot find plugin "^ fname)
    | d :: libdir ->
        let libname = d ^"/"^ fname ^".cmo" in
        PortiaLog.debug "loading lib %s\n" libname ;
        (try Dynlink.(loadfile (adapt_filename libname))
        with _ -> load_lib libdir fname)

# 107 "main.fw"


# 71 "main.fw"
let main =
    let plugins = ref [] in
    let libdir = ref [] in
    let outdir = ref "" in
    let srcfiles = ref [] in
    let addlst l s = l := s :: !l in
    Arg.(parse
        [ "-syntax", String (addlst plugins),
                     "Name of the plugin to use for parsing files \
                      (default to funnelweb)" ;
          "-libdir", String (addlst libdir),
                     "Where to read plugins from" ;
          "-outdir", Set_string outdir,
                     "Where to write output files" ;
          "-ignore-missing", Set PortiaDefinition.ignore_missing,
                     "Referenced  but never defined blocks are not \
                      an error" ;
          "-debug",  Set PortiaLog.verbose,
                     "Output debug messages" ]
        (addlst srcfiles)
        "portia - literate programming preprocessor\n\
         \n\
         portia [options] files...\n\
         Will output source code from given files.\n") ;
    if !plugins = [] then addlst plugins "funnelweb" ; (* default syntax *)
    if !libdir = [] then addlst libdir PkgConfig.plugindir ; (* default plugin dir *)
    
# 32 "main.fw"

List.iter (load_lib !libdir) !plugins ;
List.iter PortiaParse.parse !srcfiles ;
Output.all !outdir

# 97 "main.fw"


# 108 "main.fw"

