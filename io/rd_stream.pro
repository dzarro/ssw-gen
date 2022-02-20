;+
; Project     : VSO
;
; Name        : RD_STREAM
;
; Purpose     : Read a file stream
;
; Category    : utility, sockets 
;
; Syntax      : IDL> output=rd_stream(file)
;
; Inputs      : FILE  = File to read. Can be URL.
;
; Outputs     : ASCII array
;
; Keywords    : ERR = error string
;
; History     : 23-June-2018, Zarro (ADNET) - Written
;-

function rd_stream,file,err=err,_ref_extra=extra

err=''
if is_blank(file) then begin
 err='Missing input file name.'
 mprint,err
 return,''
endif

if is_url(file) then begin
 data=sock_stream(file,err=err,_extra=extra)
 if is_string(err) then return,''
 output=byte2str(data,newline=10,_extra=extra)
endif else begin
 if ~file_test(file,/regular) then begin
  err='File not found.'
  return,''
 endif
 output=rd_tfile(file,_extra=extra)
endelse

return,output
end
