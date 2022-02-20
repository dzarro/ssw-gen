;+
; Project     : SOHO-CDS
;
; Name        : VALID_MAP
;
; Purpose     : check if input image map is of valid type
;
; Category    : imaging
;
; Syntax      : valid=valid_map(map)
;
; Inputs      : MAP = image map 
;               Can be of three types -
;               Original structure; map object with map structure as
;               property; or list object with map structure as element. 
;
; Outputs     : VALID = 1/0 if valid/invalid
;
; Keywords    : OLD_FORMAT = 1/0 if using old .xp, .yp format or not
;               TYPE = 0 (structure), 1 (object map), 2 (list map)
;
; History     : Written 22 October 1997, D. Zarro, SAC/GSFC
;               13 July 2009, Zarro (ADNET)
;                - added checks for minimum required map tags
;               23 December 2010, Zarro (ADNET)
;                - added HAVE_COLORS output keyword
;               20 April 2015, Zarro (ADNET)
;                - add TRUE_COLOR keyword
;               30 August 2015, Zarro (ADNET)
;                - Removed COLOR keywords
;               29 July 2019, Zarro (ADNET)
;                - added support for LIST object
;                3 October 2019, Zarro (ADNET)
;                - added check for scalar input
;
; Contact     : dzarro@solar.stanford.edu
;-

function valid_map,map,err=err,old_format=old_format,_extra=extra,type=type

type=-1
old_format=0b
err='Missing or invalid input map.'

if n_elements(map) eq 0 then return,0b

error=0
catch,error
if error ne 0 then begin
 catch,/cancel
 err=err_state()
 message,/reset
 return,0b
endif

;-- check for required tags

if is_struct(map) then begin
 if ~tag_exist(map,'DATA') then return,0b
 if ~tag_exist(map,'TIME') then return,0b
 if ~tag_exist(map,'ID') then return,0b

 old_format=tag_exist(map,'xp') && tag_exist(map,'yp')
 if ~old_format then begin
  if ~tag_exist(map,'XC') then return,0b
  if ~tag_exist(map,'YC') then return,0b
  if ~tag_exist(map,'DX') then return,0b
  if ~tag_exist(map,'DY') then return,0b
 endif
 type=0
 err=''
 return,1b
endif

;-- LIST object?

if is_list(map) then begin
 chk=valid_map(map[0],err=err,old_format=old_format)
 if chk then type=2
 return,chk
endif

;-- MAP object?

if obj_valid(map[0]) then begin
 if obj_isa(map[0],'map') then begin
  pmap=map[0]->get(/map,/pointer)
  if ptr_exist(pmap) then begin
   chk=valid_map(*pmap,err=err,old_format=old_format)
   if chk then type=1
   return,chk
  endif
 endif
endif

return,0b & end

