;+
; Project     : VSO
;
; Name        : SOCK_DECODE
;
; Purpose     : Decode error message associated with socket response code
;
; Category    : system utility sockets
;
; Syntax      : IDL> err=sock_decode(code)
;
; Inputs      : CODE = HTTP response code returned by IDLnetURL
;                      property. CODE can be different from HTTP
;                      status code if an error occurred.
;
; Outputs     : ERR = error message associated with CODE
;
; Keywords    : None
;
; History     : 3 October 2019, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function sock_decode,code

err=''
if ~is_number(code) then return,''

case fix(code) of
   3: err='URL not properly formatted.'
   6: err='Remote server name not resolved.'
   7: err='Failed to connect to remote server.'
   9: err='FTP access denied.'
  23: err='Error writing received data to a local file.'
  28: err='Network timeout error.'
  33: err='Range requests not supported.'
  18: err='Network transfer interrupted.'
  35: err='SSL connection failed or SSL not supported on current system - '+sock_idl_agent()
  51: err='Remote server SSL certificate is invalid.'
  52: err='Remote server is not responding.'
  55: err='Sending network data failed.'
  56: err='Receiving network data failed.'
  58: err='Problem with local SSL certificate.'
  69: err='Problem with peer SSL certificate.'
  61: err='Unrecognized transfer encoding.'
  42: err=''
  else: do_nothing=1
endcase
 
return,err & end
