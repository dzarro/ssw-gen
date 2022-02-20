;+
; Project     : VSO
;
; Name        : SAVE_MODS
;
; Purpose     : Save compiled procedures/routines in IDL SAVE
;               file in $SSW/gen/idl_mods
;
; Category    : utility system
;
; Inputs      : FILE = save file name [def = 'mods.sav']
;
; Outputs     : None
;
; Keywords    : VERBOSE = set for verbose output
;
; History     : 12-Nov-2019, Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-


pro save_mods,file,_ref_extra=extra,err=err

mname='mods.sav'
mdir=local_name('$SSW/gen/idl_mods')

if is_string(file) then begin
 fdir=file_dirname(file)
 fname=file_basename(file)
 if (fdir ne '.') && (fdir ne '') then mdir=fdir
 if fname ne '' then mname=fname
endif

mfile=concat_dir(mdir,mname)

error=0
catch, error
if (error ne 0) then begin
 catch, /cancel
 err=err_state()
 mprint,err
 message,/reset
 return
endif

save,file=mfile,/routines,/ignore_nosave

sobj = obj_new('idl_savefile',mfile)
scontents = sobj->contents()
mprint,'Saved file '+mfile+' on '+scontents.date
obj_destroy,sobj

return & end
