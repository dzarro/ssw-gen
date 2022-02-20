;+
; Project     : VSO
;
; Name        : SSW_PACKAGE
;
; Purpose     : Create mirror package file for updating $SSW 
;
; Category    : utility system sockets 
;
; Syntax      : IDL> ssw_package,filename
;
; Inputs      : FILENAME = file name to write package (def in current directory)
;               RELSETS = array of directories under $SSWDB (if /DBASE)
;
; Outputs     : None
;
; Keywords    : ERR = error string
;               DBASE = set to create package for $SSWDB
;               See SSW_UPGRADE & SSWDB_UPGRADE
;
; History     : 7 August 2020 Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

pro ssw_package,filename,relsets,err=err,_ref_extra=extra,spawnit=spawnit,wget=wget,$
                dbase=dbase

err=''

if is_blank(filename) then begin
 err='Missing package filename.'
 pr_syntax,'ssw_package,filename,[/dbase]'
 return
endif

error=0
catch, error
if (error ne 0) then begin
 catch,/cancel
 err=err_state()
 mprint,err
 message,/reset
 return
endif

fdir=file_dirname(filename)
fname=file_basename(filename)
if (fdir eq '') || (fdir eq '.') then cd,current=fdir

if ~file_test(fdir,/directory) then begin
 err='Non-existent directory - '+fdir
 mprint,err
 return
endif

if ~file_test(fdir,/directory,/write) then begin
 err='No write access to directory - '+fdir
 mprint,err
 return
endif


ofile=concat_dir(fdir,fname)
if file_test(ofile) then begin
 if ~file_test(ofile,/write) then begin
  err='No write access to file- '+ofile
  mprint,err
  return
 endif
endif

site_dir=local_name('$SSW/site')
if ~file_test(site_dir,/directory) then mk_dir,site_dir
if keyword_set(dbase) then begin
 sswdb_upgrade,relsets,outdir=fdir,outpackage=fname,_extra=extra,spawnit=0,wget=0 
endif else begin
 ssw_upgrade,outdir=fdir,outpackage=fname,_extra=extra,spawnit=0,wget=0
endelse

return & end
