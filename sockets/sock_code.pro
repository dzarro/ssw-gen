;+
; Project     : VSO
;
; Name        : SOCK_CODE
;
; Purpose     : Get STATUS and RESPONSE codes from IDLnetURL object
;
; Category    : system utility sockets
;
; Syntax      : IDL> status_code=sock_code(ourl)
;
; Inputs      : OURL = IDLnetURL object
;
; Outputs     : STATUS_CODE = HTTP status code
;
; Keywords    : RESPONSE_CODE = IDLnetURL response code
;               RESPONSE_HEADER = IDLnetURL response header
;
; History     : 10 October 2019, Zarro (ADNET) - written
;               28 August 2020, Zarro (ADNET) - added /DEBUG
;
; Contact     : dzarro@solar.stanford.edu
;-

function sock_code,ourl,err=err,_ref_extra=extra,verbose=verbose,response_header=response_header,$
                   response_code=response_code,debug=debug

code=0l
err=''
ok=0b
response_code=0l
response_header=''
verbose=keyword_set(verbose)

case 1 of
 n_elements(ourl) ne 1: err='Input must be a scalar.'
 ~obj_valid(ourl): err='Input must be a valid object.'
 ~obj_isa(ourl,'idlneturl'): err='Input must be a valid IDLnetURL object.'
 else: ok=1b 
endcase

if ~ok then begin
 if verbose then mprint,err
 return,code
endif

rfile=''
ourl->getproperty,_extra=extra,response_header=response_header,response_code=response_code,response_filename=rfile

if is_string(response_header) then sock_content,response_header,code=code,_extra=extra

if keyword_set(debug) then begin
 if is_string(rfile) then begin
  if file_test(rfile,/regular) && ~file_test(rfile,/zero_length) then print,rd_ascii(rfile)
 endif
endif

return,code
end
