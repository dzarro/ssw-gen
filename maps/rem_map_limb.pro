;+
; Project     : SOHO-CDS
;
; Name        : REM_MAP_LIMB
;
; Purpose     : remove above limb pixels from a map
;
; Category    : imaging
;
; Syntax      : rmap=rem_map_limb(map)
;
; Inputs      : MAP = image map
;
; Outputs     : RMAP = MAP with above limb points set to zero
;
; Opt. Outputs: None
;
; Keywords    : ERR = error string
;               MISSING = values to set deleted data
;               DISK = remove on disk pixels instead
;
; History     : Written 26 Feb 1998, D. Zarro, SAC/GSFC
;               22-Nov-2016, Zarro (ADNET) 
;               - updated with get_map_angles to support STEREO
;
; Contact     : dzarro@solar.stanford.edu
;-

function rem_map_limb,map,disk=disk,missing=missing,_ref_extra=extra,err=err

err=''
if ~valid_map(map) then begin
 pr_syntax,'nmap=remove_map_limb(map)'
 err='Invalid input map.'
 if exist(map) then return,map else return,-1
endif

angles=get_map_angles(map,_extra=extra,err=err)
if is_string(err) then return,map

rmap=map
if ~is_number(missing) then missing=0.

radius=angles.rsun
xp=get_map_xp(map)
yp=get_map_yp(map)
pixels=sqrt((xp^2+yp^2))
if keyword_set(disk) then off_limb=where(pixels le radius,count) else $
 off_limb=where(pixels gt radius,count)

if count gt 0 then rmap.data[off_limb]=missing else begin
 err='No matching data found.'
 mprint,err
endelse

return,rmap & end
