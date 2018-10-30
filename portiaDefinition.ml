
# 327 "definitions.fw"
open Batteries


# 84 "definitions.fw"

# 48 "definitions.fw"
type location = { file : string ;
                 mtime : float ;
                lineno : int ;
                 colno : int ;
                offset : int ;
                  size : int }
# 84 "definitions.fw"


# 69 "definitions.fw"
type id = string
# 85 "definitions.fw"

type t = { locs : location list ; (* reverse order *)
             id : id ;
         output : bool }

# 329 "definitions.fw"


# 251 "definitions.fw"
(* first char is at column 0 *)
let colno_at txt =
    let rec aux colno p =
        if p = 0 || txt.[p-1] = '\n' then colno else
        aux (colno+1) (p-1) in
    aux 0 (String.length txt)

(* first line is 0 *)
let lineno_at pos txt =
    let rec aux p n =
        if p >= pos then n else
        aux (p+1) (if txt.[p] = '\n' then n+1 else n) in
    aux 0 0

let read_file fname offset size =
    let open Unix in
    let fd = openfile fname [O_RDONLY] 0 in
    lseek fd offset SEEK_SET |> ignore ;
    let str = Bytes.create size in
    let rec read_chunk prev =
        if prev < size then
            let act_sz = read fd str prev (size-prev) in
            read_chunk (prev + act_sz) in
    read_chunk 0 ;
    close fd ;
    Bytes.to_string str

# 330 "definitions.fw"


# 182 "definitions.fw"
let location_in_file file offset size =
    let mtime = Unix.((stat file).st_mtime) in
    let txt = read_file file 0 offset in
    let colno = colno_at txt
    and lineno = lineno_at offset txt in
    { file ; offset ; size ; mtime ; lineno ; colno }

# 331 "definitions.fw"


# 108 "definitions.fw"
let location_print fmt loc =
    Printf.fprintf fmt "%s:%d.%d-%d"
        loc.file loc.lineno loc.colno (loc.colno+loc.size)

let mtime_print = Float.print (* TODO: user friendly date&time? *)

let rec locations_print fmt = function
    | [] -> Printf.fprintf fmt "undefined"
    | [loc] -> location_print fmt loc
    | _loc::locs' ->
        locations_print fmt locs' (* print only the first location *)

let print fmt t =
    Printf.fprintf fmt "%s@%a" t.id locations_print t.locs

# 131 "definitions.fw"
exception FileChanged of string
let fetch_loc loc =
    let open Unix in
    let fname = loc.file in
    if (stat fname).st_mtime > loc.mtime then
        raise (FileChanged fname) ;
    read_file fname loc.offset loc.size

# 150 "definitions.fw"

let ignore_missing = ref false

let registry = Hashtbl.create 31

let add id output fname off sz =
    let loc = location_in_file fname off sz in
    PortiaLog.debug "Add definition for %s at position %a\n"
        id location_print loc ;
    Hashtbl.modify_opt id (function
        | None   -> Some { id ; output ; locs = [loc] }
        | Some t -> Some { t with locs = loc :: t.locs })
        registry

let lookup id =
    try Hashtbl.find registry id
    with Not_found ->
        if !ignore_missing then { id ; output = false ; locs = [] }
        else (
            Printf.fprintf stderr "Cannot find definition for '%s'\n" id ;
            exit 1
        )

# 199 "definitions.fw"

let linenum lineno file =
  let txt = !PortiaConfig.linenum lineno file in
  if txt = "" then "" else "\n" ^ txt ^ "\n"

let rec expanded_loc loc =
    let unexpanded = fetch_loc loc in
    PortiaLog.debug "expand '%s'\n" unexpanded ;
    (* Start with line number information. *)
    let txt = linenum loc.lineno loc.file in
    (* find_references returns a list of (id, start_offset, stop_offset) *)
    let refs = !PortiaConfig.find_references unexpanded |>
               List.sort (fun (_,o1,_) (_,o2,_) -> compare o1 o2) in
    PortiaLog.debug "found references: %a\n"
        (List.print (Tuple3.print String.print Int.print Int.print)) refs ;
    let txt, last_stop =
        List.fold_left (fun (txt,last_stop) (id,start,stop) ->
            assert (start >= last_stop) ;
            let txt = txt ^
                      (String.sub unexpanded last_stop
                                  (start - last_stop)) in
            PortiaLog.debug "appended '%s'\n"
                (String.sub unexpanded last_stop (start - last_stop)) ;

            let t' = lookup id in
            let body = expanded_body t' in
            let txt = txt ^ body in

            (* add a linenum indication that we are back in this block *)
            let txt = txt ^
                      linenum
                          (loc.lineno + (lineno_at stop unexpanded))
                          loc.file in
            txt, stop)
            (txt, 0) refs in
    (* Complete with what's left *)
    let rest = String.length unexpanded - last_stop in
    txt ^ String.sub unexpanded last_stop rest

and expanded_body t =
    List.rev t.locs |>
    List.map expanded_loc |>
    String.concat ""

# 332 "definitions.fw"

