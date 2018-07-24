;+
; Project     :	SDAC
;
; Name        :	SPLIT_TAGS
;
; Purpose     :	split duplicate tags from a structure
;
; Use         : split_tags,struct,s1,s2
;
; Inputs      :	struct = input structure (array or scalar)
;
; Outputs     :	s1,s2 = new structures with unique tags
;
; Category    :	Structure handling
;
; Written     :	Dominic Zarro (SMA/GSFC), Jan 4, 1998
;               22-May-2016, Zarro (ADNET) - cleaned up
;
; Contact     : zarro@smmdac.nascom.nasa.gov
;-

pro split_tags,s,s1,s2

delvarx,s1,s2

if ~is_struct(s) then return

;-- cycle thru each tag and build-up new structures

tags=tag_names(s)
for i=0,n_elements(tags)-1 do begin
 if ~have_tag(s1,tags[i]) then s1=add_tag(s1,s.(i),tags[i]) else $
  if ~have_tag(s2,tags[i]) then s2=add_tag(s2,s.(i),tags[i])
endfor

return & end


