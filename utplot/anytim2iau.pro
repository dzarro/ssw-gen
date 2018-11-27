;+
; NAME:
;     ANYTIM2IAU
; PURPOSE:
;     generate a (SOL2013-03-08T08:05:13) IAU target specifier
; CATEGORY:
; CALLING SEQUENCE:
;     iau = anytim2iau(time_in)
; INPUTS:
;     time in any format recognized by ANYTIM
; OPTIONAL (KEYWORD) INPUT PARAMETERS:
;     short, returns the T field in minutes only
; OUTPUTS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; MODIFICATION HISTORY:
; IDL Version 7.0, Mac OS X (darwin i386 m32)
; Journal File for hughhudson@hugh-hudsons-macbook-pro-3.local
; Working directory: /Users/hughhudson/Desktop/idl/evesoft
; Date: Fri Mar  8 08:05:18 2013
;     8-Mar-2013 (HSH)
;-
 
function anytim2iau, time_in, short=short
default, time_in, anytim(!stime)
time_in = anytim(time_in)
iau = 'SOL'+strmid(anytim(time_in,/ccsds),0,19)
if keyword_set(short) then iau = strmid(iau,0,19)
return, iau
end
