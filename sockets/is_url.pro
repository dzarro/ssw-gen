;+
; Project     : Hinode/EIS
;
; Name        : IS_URL
;
; Purpose     : check if input is a valid URL
;
; Category    : utility system sockets
;
; Syntax      : IDL> valid=is_url(url)
;
; Inputs      : URL = URL to check
;
; Outputs     : 1/0 if valid URL
;
; Keywords    : SCHEME = require that URL has http:// or ftp://
;               SECURE = 1 if HTTPS or SFTP
;               QUERY = 1 if URL has query
;               FTP = 1 if scheme is FTP
;               COMPRESSED = 1 if file is compressed
;               ERR = error string
;               SCALAR = require that URL is scalar
;               VERBOSE = set for verbose error meesages
;
; History     : Written 19-Nov-2007, Zarro (ADNET)
;               11-March-2010, Zarro (ADNET)
;               - added SCHEME
;               28-July-2013, Zarro (ADNET)
;               - improved check for FTP
;               15-Dec-2014, Zarro (ADNET)
;               - switched url_parse to parse_url
;               3-Oct-2014, Zarro(ADNET)
;               -switched parse_url back to url_parse
;               10-March-2017, Zarro (ADNET)
;               - added SECURE and QUERY keywords
;               11-Oct-2018, Zarro (ADNET)
;               - added CATCH
;               31-Dec-2018, Zarro (ADNET)
;               - /REGULAR to FILE_TEST
;               18-Jan-2019, Zarro (ADNET) 
;               - added ERR & SCALAR keywords
;                2-Mar-2019, Zarro (ADNET) 
;               - replaced FILE_TEST with FILE_SEARCH
;                4-October-2019, Zarro (ADNET)
;               - improved error propagation via keyword inheritance
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function is_url,url,scheme=scheme,secure=secure,query=query,compressed=compressed,ftp=ftp,$
                read_remote=read_remote,err=err,stc=stc,scalar=scalar,verbose=verbose,_ref_extra=extra

err=''
verbose=keyword_set(verbose)
compressed=0b & ftp=0b
secure=0b & query=0b
read_remote=0b
if is_blank(url) then begin
 err='Input URL must be non-blank string.'
 if verbose then mprint,err
 return,0b
endif

if keyword_set(scalar) && n_elements(url) gt 1 then begin
 err='Input URL must be scalar string.'
 if verbose then mprint,err
 return,0b
endif

scheme=keyword_set(scheme)
if scheme && ~has_url_scheme(url[0]) then begin
 err='Input URL requires protocol.'
 if verbose then mprint,err
 return,0b
endif

error=0
catch, error
if (error ne 0) then begin
 err=err_state()
 if verbose then mprint,err
 message,/reset
 catch,/cancel
 return,0b
endif

;-- check if URL is an existing file

chk=file_search(url[0],count=fcount)
if fcount eq 1 then return,0b

stc=url_parse(url[0])
query=is_string(stc.query)
chk=is_string(stc.host)
ftp=is_ftp(url[0])
compressed=stregex(stc.path,'(\.gz|\.Z)$',/bool)
if chk then read_remote= ~ftp && ~compressed
secure=is_ssl(url[0])

return,chk
end
