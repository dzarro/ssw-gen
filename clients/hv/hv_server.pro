;+
; Project     : HELIOVIEWER
;
; Name        : HV_SERVER
;
; Purpose     : Return HTTP address of Helioviewer (HV) API server
;
; Category    : utility system sockets
;
; Inputs      : None
;
; Outputs     : URL of HV server
;
; Opt. output : SEP = Either '&' or '/?' for the proper separator after the
;                     method name in the API.
;
; Keywords    : V1  = Set for version 1.  Ignored if either /IAS or /ROB is set.
;               IAS = Use server at IAS
;               ROB = Use server at ROB
;
; History     : 1-Dec-2015, Zarro (ADNET) - written
;               Version 2, 14-Jul-2016, William Thompson, added /IAS, /ROB
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function hv_server, sep, v1=v1, ias=ias, rob=rob

if keyword_set(rob) then begin
    server = 'http://swhv.oma.be/hv/api/index.php?action='
    sep = '&'
end else if keyword_set(ias) then begin
    server = 'http://helioviewer.ias.u-psud.fr/helioviewer/api/index.php?action='
    sep = '&'
end else begin
    if keyword_set(v1) then version = 'v1' else version = 'v2'
    server = 'http://api.helioviewer.org/' + version + '/'
    sep = '/?'
endelse
;
return, server
end
