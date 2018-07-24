;+
; Project     : HESSI
;
; Name        : WIDGET_ID
;
; Purpose     : Return group widget ID of registered GUI
;
; Category    : widgets utility
;
; Syntax      : IDL> id=widget_id(name)
;
; Inputs      : NAME = GUI string name (e.g. 'goes')
;
; Keywords    : None
;
; Outputs     : ID = widget ID of GUI
;
; History     : 28-Dec-2017, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

function widget_id,name

forward_function lookupmanagedwidget

if is_blank(name) then return,-1L

error=0
catch,error
if error ne 0 then begin
 catch,/cancel
 mprint,err_state()
 return,-1L
endif

quiet=!quiet
!quiet=1
xmanager
!quiet=quiet

id=call_function('lookupmanagedwidget',strlowcase(name))

if widget_info(id,/valid) then return,id else return,-1L

end 
