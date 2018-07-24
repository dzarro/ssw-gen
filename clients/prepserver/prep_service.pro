;+
; Project     : VSO
;
; Name        : PREP_SERVICE
;
; Purpose     : Wrapper around PREP_FILE called as Web service
;
; Category    : utility analysis
;
; Keywords    : PFILE = file to prep (can be URL)
;               EXTRA = prep keywords to pass to prep routine
;               ERR = error string
;               SERVER = Server hosting prepped file
;               PORT = Server port 
;               JSON = JSON string with URL of prepped file
;               SESSION = session ID
;               THREAD = run service in background thread
;
; History     : 19-March-2016, Zarro (ADNET) - written
;               28-January-2018, Zarro (ADNET) - added 'prep' subdirectory and THREAD keyword
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro prep_service,file=pfile,_extra=extra,server=server,port=port,err=err,$
                     json=json,session=session,thread=thread

err='' & json=''
jstruct={input:'',output:'',status:0,err_message:''}

if is_blank(pfile) then begin
 err='Input file not entered.'
 jstruct.err_message=err
 mprint,err
 json=json_serialize(jstruct)
 return
endif
 
file=pfile
jstruct.input=file
prep_dir=chklog('HTTP_WRITE')
if is_blank(prep_dir) then prep_dir=get_temp_dir()
if ~file_test(prep_dir,/dir,/write) then begin
 err='Write access denied.'
 mprint,err
 jstruct.err_message=err
 json=json_serialize(jstruct)
 return
endif

prep_host=''
if is_string(server) then begin
 prep_host='http://'+trim(server)
 if is_number(port) then prep_host=prep_host+':'+trim(port)
endif

;-- check if URL entered. If remote host is same as prep host,
;   then file is local

remote_file=is_url(file,/scheme)
if remote_file then begin
 stc=url_parse(file)
 file_server=stc.scheme+'://'+stc.host+':'+trim(stc.port)
 remote_file=strlowcase(file_server) ne strlowcase(prep_host)
 if ~remote_file then file='/'+stc.path
endif

if remote_file then begin
 mprint,'Checking remote file..'
 resp=sock_head(file)
 sock_content,resp,disposition=disposition,code=code
 if code ne 200 then begin
  err='Input URL file not found.'
  mprint,err
  jstruct.err_message=err
  json=json_serialize(jstruct)
  return
 endif
 if is_string(disposition) then ofile=disposition else begin
  stc=url_parse(file)
  ofile=local_name(file_basename(stc.path))
 endelse
endif else begin
 file=concat_dir(prep_dir,file)
 chk=file_test(file,/read,/reg)
 if ~chk then begin
  err='Input file not found.'
  mprint,err
  jstruct.err_message=err
  json=json_serialize(jstruct)
  return
 endif
 ofile=local_name(file_basename(file))
 if is_compressed(ofile,type) then ofile=str_replace(ofile,'.'+type,'')
endelse

;-- output location of prepped file

if is_number(session) then tsession=trim(session) else tsession=session_id()
psession=concat_dir('prep',tsession)
out_dir=concat_dir(prep_dir,psession)
file_mkdir,out_dir

output_url=concat_dir(prep_host+'/'+psession,'prepped_'+ofile)
jstruct.output=output_url
jstruct.status=1b

;-- send prep command to background thread

if keyword_set(thread) then $
 thread,'prep_file',file,out_dir=out_dir,_extra=extra,err=err,/new_thread else $
  prep_file,file,out_dir=out_dir,_extra=extra,err=err

if is_string(err) then begin
 mprint,err
 jstruct.status=0b
 jstruct.err_message=err
endif

json=json_serialize(jstruct)

return
end

