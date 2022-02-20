;+
; Project     : HESSI
;                  
; Name        : MK_DIR
;               
; Purpose     : wrapper around FILE_MKDIR that catches errors
;                             
; Category    : system utility
;               
; Syntax      : IDL> mk_dir,dir
;                                        
; Outputs     : None
;                   
; History     : 17 Apr 2003, Zarro (EER/GSFC)
;               13 Apr 2004, Zarro (L-3Com/GSFC) - added CHMOD
;                1 Oct 2011, Zarro (ADNET) - added ERR keyword
;               10 Jan 2019, Zarro (ADNET) - pass _extra to FILE_MKDIR
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro mk_dir,dir,_extra=extra,err=err

err=''
if is_blank(dir) then begin
 err='Blank directory name entered.'
 mprint,err
 return
endif

v54=since_version('5.4')

for i=0,n_elements(dir)-1 do begin

 error=0
 catch,error
 if error ne 0 then begin
  err=err_state()
  mprint,err
  message,/reset
  catch,/cancel
  continue
 endif

 dname=chklog(dir[i],/pre)
 if is_blank(dname) then continue

 if ~is_dir(dname) then begin
  if v54 then file_mkdir,dname,_extra=extra else espawn,'mkdir '+dname,/noshell
 endif

 if is_struct(extra) then begin
  if is_dir(dname) then chmod,dname,_extra=extra
 endif

endfor

return & end
