;+
; Project     : Hinode/EIS
;
; Name        : IS_URL
;
; Purpose     : check if file name is URL
;
; Category    : utility system sockets
;
; Inputs      : FILE = file to check
;
; Outputs     : 1/0 if valid URL
;
; Keywords    : SCHEME = http:// or ftp:// has to appear in the input
;               SECURE = 1 if HTTPS or SFTP
;               QUERY = 1 if URL has query
;               FTP = 1 if scheme is FTP
;               COMPRESSED = 1 if file is compressed
;
; History     : Written 19-Nov-2007, D.M. Zarro (ADNET/GSFC)
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
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function is_url,file,scheme=scheme,secure=secure,query=query,compressed=compressed,ftp=ftp,$
                read_remote=read_remote

compressed=0b & ftp=0b
secure=0b & query=0b
read_remote=0b
if is_blank(file) then return,0b
if file_test(file[0]) then return,0b

stc=url_parse(file[0])
query=is_string(stc.query)
chk=is_string(stc.host)
if keyword_set(scheme) then chk=is_string(stc.host) && has_url_scheme(file[0])
ftp=is_ftp(file[0])
compressed=stregex(stc.path,'(\.gz|\.Z)$',/bool)
if chk then read_remote= ~ftp && ~compressed

secure=stregex(file,'(https\:)|(sftp\:)',/bool,/fold)

return,chk
end
