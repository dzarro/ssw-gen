;+
; Project     : VSO
;
; Name        : WIDGET_DISPLAY
;
; Purpose     : Return output of WIDGET_INFO(/DISPLAY)
;
; Category    : utility widgets graphics
;
; Syntax      : IDL> chk=widget_display()
;
; Inputs      : None
;
; Outputs     : CHK = 1 if environment supports X-window display
;
; Keywords    : None
;
; History     : 6-Sep-2019, Zarro (ADNET)
;-

function widget_display

defsysv,'!widget_display',exists=exists
if ~exists then defsysv,'!widget_display',widget_info(/display)
return,!widget_display

end
