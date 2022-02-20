;+
; Project     : HESSI
;                  
; Name        : DEL_DIR
;               
; Purpose     : wrapper around FILE_DELETE that checks protections
;                             
; Category    : system utility
;               
; Syntax      : IDL> del_dir,dir
;
; Inputs      : DIR = directory string names
;                                        
; Outputs     : None
;
; Keywords    : RECURSE = set to recurse on directories
;                   
; History     : 10-Jan-2019, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro del_dir,dir,_extra=extra,err=err,verbose=verbose

err=''
verbose=keyword_set(verbose)
chmod,dir,_extra=extra,/u_write,/u_read,err=err,verbose=verbose
if is_string(err) then return

for i=0,n_elements(dir)-1 do begin

 error=0
 catch,error
 if error ne 0 then begin
  err=err_state()
  mprint,err
  catch,/cancel
  continue
 endif

 tdir=strtrim(dir[i],2)
 if is_blank(tdir) then continue
 if ~file_test(tdir,/write,/direc) then continue
 file_delete,tdir,_extra=extra,/allow_nonexistent,verbose=verbose
endfor

return & end
