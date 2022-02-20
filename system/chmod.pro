;+
; Project     : HESSI
;                  
; Name        : CHMOD
;               
; Purpose     : wrapper around FILE_CHMOD that recurses and catches errors
;                             
; Category    : system utility
;               
; Syntax      : IDL> file_chmod,file
;
; Inputs      : FILE = String array of files (directories) to modify
;               MODE = Optional bit mask (e.g. '0400'o to allow read by owner)
;                                        
; Outputs     : None
;
; Keywords    : RECURSIVE = Set to recurse on subdirectories and files
;               VERBOSE = Set for verbose output
;               ERR = Error message
;               ACCESS keywords (e.g./G_READ to allow read access for group)
;                   
; History     : 17-Apr-2003, Zarro (EER/GSFC)
;               12-Feb-2019, Zarro (ADNET/GSFC) - added recursion
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro chmod,file,mode,_extra=extra,verbose=verbose,recursive=recursive,err=err

err=''
verbose=keyword_set(verbose)

if is_blank(file) then begin
 err='Missing input.'
 if verbose then mprint,err
 return
endif

use_mode=exist(mode)
use_key=is_struct(extra)
recursive=keyword_set(recursive)
if ~use_mode && ~use_key then return

for i=0,n_elements(file)-1 do begin
 tfile=strtrim(file[i],2)
 dfile=0b & direc=0b
 if is_string(tfile) then begin
  dfile=file_test(tfile,/reg)
  direc=file_test(tfile,/direc)
  if ~dfile && ~direc then begin
;   err='Non-existent input.'
;   if verbose then mprint,err
   continue
  endif
 endif

 error=0
 catch,error
 if error ne 0 then begin
  err=err_state()
  if verbose then mprint,err
  catch,/cancel
  message,/reset
  continue
 endif

 if use_mode then file_chmod,tfile,mode else $
  file_chmod,tfile,_extra=extra

;-- recurse on subdirectories

 if direc && recursive then begin
  dir=tfile
  chmod,dir,/u_read,err=err,verbose=verbose
  if is_string(err) then continue
  path=concat_dir(dir,'*')
  out=file_search(path,count=fcount,/match_initial_dot)
  if fcount gt 0 then chmod,out,mode,_extra=extra,verbose=verbose,err=err
  out=file_search(path,count=dcount,/test_directory,/match_initial_dot)
  if dcount gt 0 then chmod,out,mode,_extra=extra,verbose=verbose,/recursive,err=err
 endif
 
endfor

return

end
