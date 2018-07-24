;+
; Project     : HELIOVIEWER
;
; Name        : HV_SEARCH
;
; Purpose     : Return metadata for closest JPEG2000 file in time for specified SOURCE ID
;
; Category    : utility system sockets
;
; Example     : IDL> a=hv_search('1-may-10',15,header=header)
;               IDL> help,a
;               ** Structure <78351a8>, 9 tags, length=88, data length=84, refs=1:
;                ID              STRING    '947636'
;                DATE            STRING    '2010-06-02 00:05:30'
;                SCALE           DOUBLE          0.61829595
;                WIDTH           LONG64                      4096
;                HEIGHT          LONG64                      4096
;                REFPIXELX       DOUBLE           2044.0100
;                REFPIXELY       DOUBLE           2054.1800
;                SUNCENTEROFFSETPARAMS
;                OBJREF    <ObjHeapVar563(LIST)>
;                LAYERINGORDER   LONG64                         1
;
; Inputs      : TIME = input time to check
;               SOURCE_ID = data source ID (from HV_SOURCE)
;
; Outputs     : META = metadata record
;
; Keywords    : ERR = error string
;               HEADER = JPEG2000 file header
;
; History     : 1-Dec-2015, Zarro (ADNET) - written
;               14-Jul-2016, William Thompson, update server calls
;               12-Nov-2016, Zarro (ADNET) - added more stringent error checks
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function hv_search,time,source_id,_ref_extra=extra,header=header,err=err

header=''  & err=''

if ~since_version('8.2') then begin
 err='Need IDL version 8.2 or better.'
 mprint,err
 return,''
endif

if ~valid_time(time) || ~is_number(source_id) then begin
 err='Invalid input time or source ID.'
 mprint,err
 pr_syntax,'meta=hv_search(time,source_id)'
 return,''
endif

;-- check for existence of data source

date=anytim2utc(time,/ccsd)+'Z'
request = hv_server(sep, _extra=extra) + 'getClosestImage' + sep + 'date=' + $
          date + '&sourceId=' + trim(source_id)
sock_list,request,output,_extra=extra,err=err

switch 1 of
 1: if is_string(err) then break
 2: if is_blank(output) then break
 3: if n_elements(output) ne 1 then break
 4: if stregex(output[0],'error',/bool,/fold) then break
else: begin   
  meta=call_function('json_parse',output,/tostruct)
  if arg_present(header) then begin
   if is_struct(meta) then begin
    if have_tag(meta,'id') then begin
     query = hv_server(sep, _extra=extra) + 'getJP2Header' + sep + 'id=' + $
                trim(meta.id)
     sock_list,query,header,_extra=extra,err=err
    endif
   endif
  endif
  return,meta
 end
endswitch

err='No data found for time and source ID.'
mprint,err
return,''
end

