;+
; Project     : RHESSI
;
; Name        : DOTPROP__DEFINE
;
; Purpose     : Convenient base class that inherits IDL_OBJECT
;               to enable new IDL '.' syntax for accessing and
;               setting properties.
;
; Category    : Objects
;
; History     : Written 15 December 2010, D. Zarro (ADNET)
;               8 February 2018, Zarro (ADNET) 
;                - check for parent level properties
;
; Contact     : dzarro@solar.stanford.edu
;-

;----------------------------------------------------------------------

pro dotprop::getproperty,_ref_extra=extra

;-- don't bother if no property is being requested 

if ~is_string(extra) then return

;-- check first if property name is at parent level

struct=obj_struct(self)
match,tag_names(struct),strupcase(extra),p,q,count=count
if count gt 0 then begin
 for i=0,count-1 do (scope_varfetch(extra(q[i]),/ref))=self.(p[i])
 return
endif

;-- return if no GET method

if ~have_method(self,'get') then return

nkey=n_elements(extra)
for i=0,nkey-1 do begin
 struct=create_struct(extra[i],1)
 val=self->get(_extra=struct)
 (scope_varfetch(extra[i],/ref))=val
endfor

return & end

;--------------------------------------------------------------------------

pro dotprop::setproperty,_extra=extra

;-- don't bother if no property is being set or there is no SET method

if ~is_struct(extra) then return
if ~have_method(self,'set') then return

self->set,_extra=extra

return & end


;----------------------------------------------------------------------------

pro dotprop__define

  temp =  {dotprop,dotprop_dummy:0B,inherits idl_object}

return & end
