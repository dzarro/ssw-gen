;+
; Project     : VSO
;
; Name        : FILE_CREATE
;
; Purpose     : Create an empty regular file (if it doesn't exist)
;
; Category    : utility system
;
; Syntax      : IDL> file_create,file
;
; Inputs      : FILE = string file name to create
;
; Keywords    : ERR = error string
;
; History     : 26 January 2019, Zarro (ADNET) - written
;-

pro file_create,file,err=err,verbose=verbose

err=''
verbose=keyword_set(verbose)
case 1 of
 n_elements(file) gt 1: err='Input file name must be scalar string.'
 is_blank(file): err='Input file name must be non-blank string.'
 file_test(file,/reg): err='File exists.'
 file_test(file,/direc): err='File exists as a directory.'
 else: begin
  fdir=local_name(file_dirname(file))
  if (fdir eq '.' || fdir eq '') then cd,cur=fdir
  if ~file_test(fdir,/direct) then err='Non-existent parent directory: ' +fdir else $
   if ~file_test(fdir,/write) then err='Denied write access to: '+fdir
 end
endcase

if is_string(err) then begin
 if verbose then mprint,err
 return
endif

dfile=local_name(file)
openw,lun,dfile,/get_lun
close_lun,lun

if ~file_test(dfile,/reg) then begin
 err='File not created: '+dfile
 if verbose then mprint,err
endif else begin
 if verbose then mprint,'File created: '+dfile
endelse
 
return
end
