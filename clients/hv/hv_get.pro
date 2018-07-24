;+
; Project     : HELIOVIEWER
;
; Name        : HV_GET
;
; Purpose     : Download nearest JPEG2000 file for specified SOURCE ID
;
; Category    : utility system sockets
;
; Example     : IDL> hv_get,'1-may-07',14
;
; Inputs      : TIME = time/date to search (UT)
;               SOURCE_ID = data source ID (from HV_SOURCE)
;
; Outputs     : See keywords
;
; Keywords    : LOCAL = name of downloaded file
;               ERR = error string
;
; History     : 1-Dec-2015, Zarro (ADNET) - written
;               14-Jul-2016, William Thompson, update server call
;               12-Nov-2016, Zarro (ADNET) - added more stringent error checks
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro hv_get,time,source_id,_ref_extra=extra,err=err

err=''
if ~valid_time(time) then begin
 err='Missing or invalid input time.'
 mprint,err
 return
endif

if ~is_number(source_id) then begin
 pr_syntax,'hv_get,time,source_id'
 err='Missing or invalid Source ID.'
 mprint,err
 return
endif

;-- check for existence of data source

date=anytim2utc(time,/ccsd)+'Z'
request = hv_server(sep, _extra=extra) + 'getJP2Image' + sep + 'date=' + date + $
          '&sourceId=' + trim(source_id)
check=request+'&jpip=true'
sock_list,check,output,err=err

switch 1 of
 1: if is_string(err) then break
 2: if is_blank(output) then break
 3: if n_elements(output) ne 1 then break
 4: if stregex(output[0],'error',/bool,/fold) then break
else: begin
  dprint,'% request: '+request
  sock_get,request,_extra=extra,err=err
  return
 end
endswitch 

err='No data found for Time and Source ID.'
mprint,err
return
end
