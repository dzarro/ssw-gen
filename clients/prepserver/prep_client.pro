;+
; Project     : VSO
;
; Name        : PREP_CLIENT
;
; Purpose     : Client to send file to PREP_SERVER
;
; Category    : utility sockets analysis
;
; Inputs      : FILE = file to prep (can be URL)
;
; Outputs     : OFILE = URL of  prepped file
;
; Keywords    : EXTRA = prep keywords to pass to prep routine
;               ERR = error string
;               SESSION = unique session ID number
;               JSON = JSON string with URL of prepped file
;               SERVER = remote PREP_SERVER host name
;               PORT = remote PREP_SERVER port number
;               WAIT_TIME = seconds to wait before giving up 
;               trying to download the prepped file [def = 60 secs]
;
; History     : 29-March-2016, Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro prep_client_callback, id, userdata

ofile=userdata.ofile
tset=userdata.tset
wait_time=userdata.wait_time
last_time=userdata.last_time
t1=systim(/sec)
tdiff=t1-last_time
if tdiff gt wait_time then begin
 mprint,'PREP_SERVER taking too long. Giving up.'
 return
endif

;-- download file if available on server

chk=sock_response(ofile,code=code)
if code eq 200 then begin
 sock_get,ofile,local=local,_extra=userdata,/no_check,err=err
 if file_test(local,/read) && is_blank(err) then begin 
  mprint,'Prepped file available locally at - '+local
 endif
 return
endif

!null = timer.set(tset, 'prep_client_callback', userdata) 

return & end

;-----------------------------------------------------------------
pro prep_client,file,ofile,json=json,_extra=extra,err=err,$
                port=port,server=server,wait_time=wait_time

err='' & json='' & ofile=''
sock_def_server,dserver,dport
if is_blank(server) then server=dserver
if ~is_number(port) then port=dport
if ~is_number(wait_time) then wait_time=60.
 
prep_server='http://'+server+':'+trim(port)

if is_blank(file) then begin
 err='Input file not entered.'
 mprint,err
 pr_syntax,'prep_client,file,ofile,json=json'
 return
endif
 
if ~have_network(prep_server,interval=1,/no_accept) then begin
 err='PREP_SERVER not running at - '+prep_server
 mprint,err
 return
endif

;-- if not URL then have to upload it to PREP_SERVER

if is_url(file,/scheme) then location=file else begin
 sock_put,file,prep_server,err=err,head=head
 if is_string(err) then return
 sock_content,head,location=location,code=code
 if (code ne 201) || is_string(err) || is_blank(location) then begin
  mprint,'Failed to upload file. Check PREP_SERVER configuration.'
  return
 endif
 mprint,'File uploaded successfully.'
endelse

prep_cmd=prep_server+'/prep_service?file="'+location+'"'
query=stc_query(extra)
if is_string(query) then prep_cmd=prep_cmd+'&'+query

;if verbose then begin
; mprint,'Executing -'
; print,prep_cmd
;endif

dprint,prep_cmd

sock_list,prep_cmd,json,err=err

;-- check and report errors

if is_string(err) then return
if is_blank(json) then return
result=json_parse(json,/tostruct)
if ~have_tag(result,'output') then return
error=result.err_message
if is_string(error) || (result.status eq 0) then begin
 if is_string(error) then mprint,error
 return
endif

mprint,'Prepped file will be available remotely at - ' 
ofile=result.output
print,ofile

;-- start timer to download file from server

tset=10.
t0=systim(/sec)
userdata={tset:tset,ofile:ofile,wait_time:wait_time,last_time:t0}
userdata=join_struct(userdata,extra)

!null = timer.set(tset, 'prep_client_callback', userdata) 

return
end
