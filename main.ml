# 96 "main.fw"
open Batteries

# 51 "main.fw"
let load_lib libdir fname =
    let libname = libdir ^"/"^ fname ^".cmo" in
    PortiaLog.debug "loading lib %s\n" libname ;
    Dynlink.(loadfile (adapt_filename libname))
# 98 "main.fw"

# 66 "main.fw"
let main =
    let plugins = ref [] in
    let libdir = ref PkgConfig.plugindir in
    let srcfiles = ref [] in
    let addlst l s = l := s :: !l in
    Arg.(parse
        [ "-syntax", String (addlst plugins),
                     "Name of the plugin to use for parsing files \
                      (default to funnelweb)" ;
          "-libdir", Set_string libdir,
                     "Where to read plugins from" ;
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
# 32 "main.fw"
    
    List.iter (load_lib !libdir) !plugins ;
    List.iter PortiaParse.parse !srcfiles ;
    Output.all ()
# 88 "main.fw"
    
# 99 "main.fw"

