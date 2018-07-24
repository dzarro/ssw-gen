;+
; Project     : HELIOVIEWER
;
; Name        : HV_SOURCE
;
; Purpose     : Return Helioviewer (HV) SOURCE ID
;
; Category    : utility system sockets
;
; Example     : IDL> source_id=hv_source(obs='SOHO',inst='EIT',meas='304')
;               IDL> print,source_id
;
; Inputs      : See keywords
;
; Outputs     : SOURCE_ID = matching source ID
;
; Keywords    : Observatory = observatory (e.g. 'STEREO_A')
;               Instrument = instrument (e.g. 'SECCHI')
;               Detector = detector (e.g. 'EUVI')
;               Measurement = measurement (e.g. 171)
;
; Side effects: Note that the syntax of the call will depend in some cases on
;               which HV server is being used.  For example, the correct call
;               for the IAS server would be:
;
;               IDL> source_id=hv_source(obs='SOHO',inst='EIT',det='EIT',meas='304')
;
;               while that same call would fail on the default helioviewer.org
;               server.
;
; History     : 1-Dec-2015, Zarro (ADNET) - written
;               Version 2, 14-Jul-2016, William Thompson, update server call, caching
;               12-Nov-2016, Zarro (ADNET) - added more stringent error checks
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function hv_source,detector=detector,instrument=instrument,observatory=observatory,$
                   measurement=measurement,err=err,_ref_extra=extra
err=''

if ~since_version('8.2') then begin
 err='Need IDL version 8.2 or better.'
 mprint,err
 return,-1
endif

common hv_source, server, results

if n_elements(server) eq 0 then server = ''

server0 = hv_server(sep, _extra=extra)
if (server ne server0) or ~is_struct(results) then begin
 server = server0
 sources=server+'getDataSources'
 if sep eq '/?' then sources = sources + '/'
 sock_list,sources,json,err=err
 if is_string(err) || (n_elements(json) ne 1)  then begin
  mprint,err & return,-1
 endif
 results=call_function('json_parse',json,/tostruct)
endif

;-- parse JSON output into a structure and drill for source ID

if ~is_struct(results) then begin 
 err='Helioviewer source file not readable.'
 mprint,err & return,-1
endif

req='results'
if is_string(observatory) then req=req+'.'+observatory
if is_string(instrument) then req=req+'.'+instrument
if is_string(detector) then req=req+'.'+detector
if exist(measurement) then begin
 if is_number(measurement) then dmess='_'+trim(measurement) else $
  if string(measurement) then dmess=measurement
 if is_string(dmess) then req=req+'.'+dmess
endif

state='source_id='+req+'.sourceid'
status=execute(state,1,1)
if status eq 1 then return,source_id

err='Failed to determine SOURCE ID.'
mprint,err
return,-1

end

