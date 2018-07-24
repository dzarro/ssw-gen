;+
; Project     : HESSI
;
; Name        : XBANNER
;
; Purpose     : Create banner text widget that can be updated with text
;
; Category    : widgets utility
;
; Syntax      : IDL> xbanner,text
;
; Inputs      : TEXT = string array to display
;
; Keywords    : KILL = set to close banner
;
; Outputs     : None
;
; History     : 28-Dec-2017, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

pro xbanner,text,_ref_extra=extra,kill=kill,wtext=wtext

common xbanner,wbase

if keyword_set(kill) then begin
 xkill,wbase
 return
endif

if ~is_string(text) then return
ysize=10
xtext,text,wbase=wbase,/no_block,xsize=60,ysize=ysize,space=0,/dismiss,_extra=extra,/scroll

;-- scroll to bottom if number of text lines exceeds window size

wtext=widget_info(wbase,/child)
widget_control,wtext,get_value=utext
np=n_elements(utext)

if np gt ysize then widget_control,wtext,set_text_top_line=np

return
end

