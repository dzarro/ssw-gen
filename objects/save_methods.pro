;+
; Project     : VSO
;
; Name        : SAVE_METHODS
;
; Purpose     : The regular SAVE method for saving routines doesn't save
;               all the methods for an object class definition. 
;               For example,
;               IDL> save,'mirror__define',/routines
;               will only save the class definition procedure but not the
;               associated methods.
;               This procedure does that by compiling all the methods
;               and saving then individually.
;             
; Category    : objects, utility
;
; Syntax      : IDL> save_methods,object,filename=filename
;
; Inputs      : OBJECT = object reference or class definition name
;
; Keywords    : FILENAME = output file name for save file.
;               [def = class_name.sav]
;               ERR = error messages
;               QUIET = turn off output messages
;               ADDITIONAL = comma-separated additional routines to
;               include.
;               OUT_DIR = output directory for save file.
;
; Outputs     : None
;
; History     : 18-November-2020 Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

pro save_methods,object,filename=filename,_ref_extra=extra,quiet=quiet,err=err,$
                        additional=additional,out_dir=out_dir

err=''
verbose=~keyword_set(quiet)

;-- determine output save file name from object class name

name='idlsave'
if obj_valid(object) then name=obj_class(object) else $
 if is_string(object) then name=object
name=strlowcase(name)
if is_blank(filename) then filename=name+'.sav'

;-- extract method names

methods=obj_methods(object,_extra=extra,err=err,verbose=0b)
if is_string(err) then begin
 mprint,err
 return
endif

if is_blank(methods) then begin
 err='No methods associated with - '+name
 if verbose then mprint,err
 return
endif

odir=file_dirname(filename)
if (odir eq '.') || (odir eq '') then cd,current=odir
if is_string(out_dir) then odir=out_dir

if ~file_test(odir,/dir) then begin
 err='Non-existent directory - '+odir
 if verbose then mprint,err
 return
endif
if ~file_test(odir,/dir,/write) then begin
 err='No write access to - '+odir
 if verbose then mprint,err
 return
endif
ofile=local_name(concat_dir(odir,file_basename(filename)))

;-- compile and extract method names

resolve_routine,name+'__define',/either,/compile_full
m=stregex(methods,'.*('+name+'::[^,]+).*',/ext,/sub)

chk=where(m[1,*] ne '',count)
if count eq 0 then begin
 err='No methods associated with - '+name
 if verbose then mprint,err
 return
endif

methods=reform(m[1,chk])
def_name='"'+name+'__define"'
cmethods=def_name+','+strjoin('"'+methods+'"',',')

;-- check if additional routines are included

if is_string(additional) then begin
 add=strsplit(additional,',',/extract)
 for i=0,n_elements(add)-1 do begin
  if have_proc(add[i]) then begin
   resolve_routine,add[i],/either,/compile_full
   cmethods=cmethods+',"'+add[i]+'"'
  endif
 endfor
endif

state='save,'+cmethods+',/routines,/ignore_nosave,filename='+'"'+ofile+'"'
success=execute(state)

if ~success then begin
 err='Failed to save methods to - '+ofile
 if verbose then mprint,err
 return
endif

if verbose then mprint,'Saved methods to - '+ofile

return
end
