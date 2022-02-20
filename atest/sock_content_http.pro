;+
; Project     : VSO
;
; Name        : SOCK_CONTENT_HTTP
;
; Purpose     : Parse HTTP response content
;
; Category    : utility system sockets
;
; Syntax      : IDL> sock_content_http,response
;
; Inputs      : RESPONSE = HTTP response string (scalar or vector)
;
; Outputs     : See keywords
;
; Keywords    : CODE = response status code
;             : TYPE = supported type
;             : SIZE = number of bytes in return content
;             : DISPOSITION = alternate return filename
;             : CHUNKED = 1 if content is chunked
;             : LOCATION = alternate URL if redirected
;             : CONTENT_LOCATION = alternate file name on server?
;             : DATE = content date stamp
;             : RANGE = input byte range (if byte serving)
;             : RESP_ARRAY = response header in string array format   
;
; History     : 23-Jan-2013, Zarro (ADNET) - Written
;               24-Nov-2013, Zarro (ADNET) - renamed from HTTP_CONTENT
;               18-Nov-2014, Zarro (ADNET) - added check for scalar response
;               29-Mar-2016, Zarro (ADNET) - fixed bug where code not returned 
;               25-Aug-2016, Zarro (ADNET) - added CONTENT-LOCATION
;                2-Oct-2016, Zarro (ADNET) - renamed from SOCK_CONTENT
;               19-Jan-2019, Zarro (ADNET) - added RESPONSE_CODE
;                4-Oct-2019, Zarro (ADNET) - removed RESPONSE_CODE
;               23-Jul-2020, Zarro (ADNET) - added optional quotes for
;                                            DISPOSITION
;                7-May-2021, Zarro (ADNET) - added REF_EXTRA
;               20-Feb-2022, Zarro (ADNET) - applied URL_FIX to LOCATION
;-

pro sock_content_http,response,type=type,size=bsize,date=date,$
               disposition=disposition,location=location,code=code,$
               chunked=chunked,range=range,resp_array=resp,accept=accept,$
               content_location=content_location,_ref_extra=extra

resp=''
if is_blank(response) then begin   
 type='' & date='' & bsize=0l & disposition='' & location='' & code=0L
 chunked=0b & accept='' & content_location='' 
 return
endif
resp=response

if n_elements(resp) eq 1 then resp=byte2str(byte(resp),newline=13,skip=2)

;-- get type

if arg_present(type) then begin
 type=''
 cpos=stregex(resp,'Content-Type:',/bool,/fold)
 chk=where(cpos,count)
 if count gt 0 then begin
  temp=resp[chk[0]]
  pos=strpos(temp,':')
  if pos gt -1 then type=strtrim(strmid(temp,pos+1,strlen(temp)),2)
 endif
endif else type=''

;-- get last modified data

if arg_present(date) then begin
 date=''
 cpos=stregex(resp,'Last-Modified:',/bool,/fold)
 chk=where(cpos,count)
 if count gt 0 then begin
  temp=resp[chk[0]]
  pos=strpos(temp,':')
  if pos gt -1 then begin
   time=strtrim(strmid(temp,pos+1,strlen(temp)),2)
   pie=str2arr(time,delim=' ')
   date=trim(anytim2utc(pie[1]+'-'+pie[2]+'-'+pie[3]+' '+pie[4],/vms))
 endif
endif
endif else date=''

;-- get size

if arg_present(bsize) then begin
 bsize=0l
 cpos=stregex(resp,'Content-Length:',/bool,/fold)
 chk=where(cpos,count)
 if count gt 0 then begin
  temp=resp[chk[0]]
  pos=strpos(temp,':')
  if pos gt -1 then bsize=long(strmid(temp,pos+1,strlen(temp)))
 endif
endif else bsize=0l

;-- get content disposition

if arg_present(disposition) then begin
 disposition=''
 disposition_index=where(stregex(resp,'^Content-Disposition:',/bool,/fold),count)
 if (count gt 0) then begin
  disp = resp[disposition_index]
  temp = stregex( disp, '^Content-Disposition:.*filename="?([^"]*)"?', /extract, /subexp,/fold)
  file = temp[1]

;-- strip out any suspicious characters

  if is_string(file) then begin
   temp = strsplit( file,'[^-0-9a-zA-Z._]+', /regex, /extract )
   disposition=strjoin( temp,'_')
  endif
 endif
endif else disposition=''

;-- redirection?

if arg_present(location) then begin
 location=''
 redir=stregex(resp,'^Location: *([^ ]+)',/fold,/extract,/sub)
 chk=where(redir[1,*] ne '',count)
 if count gt 0 then location=url_fix(strtrim(redir[1,chk[0]],2))
endif else location=''

;-- Content Location

if arg_present(content_location) then begin
 content_location=''
 redir=stregex(resp,'^Content-Location: *([^ ]+)',/fold,/extract,/sub)
 chk=where(redir[1,*] ne '',count)
 if count gt 0 then content_location=strtrim(redir[1,chk[0]],2)
endif else content_location=''

;-- status code

if arg_present(code) then begin
 code=0L
 u=stregex(resp,'http.+ ([0-9]+)(.*)',/sub,/extr,/fold)
 chk=where(u[1,*] ne '',count)
 if count gt 0 then code=long(u[1,chk[0]])
endif else code=0L

;-- chunked?

if arg_present(chunked) then begin
 chk=where(stregex(resp,'Transfer-Encoding: chunked',/bool,/fold) eq 1,count)
 chunked=(count gt 0)
endif else chunked=0b

;-- ranges requested?

if arg_present(range) then begin
 accept_ranges=''
 cpos=stregex(resp,'Accept-Ranges:',/bool,/fold)
 chk=where(cpos,count)
 if count gt 0 then begin
  temp=resp[chk[0]]
  pos=strpos(temp,':')
  if pos gt -1 then accept_ranges=strmid(temp,pos+1,strlen(temp))
 endif
 if is_blank(accept_ranges) then mprint,'Accept-Ranges not supported.',/info
endif

if arg_present(accept) then begin
 accept=''
 redir=stregex(resp,'Accept: *([^ ]+)',/fold,/extract,/sub)
 chk=where(redir[1,*] ne '',count)
 if count gt 0 then accept=strtrim(redir[1,chk[0]],2)
endif else accept=''

return & end
