;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_DISPLAY
;
; Purpose     :	Display SUNGLOBE data on sphere
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Called from SUNGLOBE_EVENT to display the data on the sphere
;               whenever an image has been added, subtracted, or moved. 
;
; Syntax      :	SUNGLOBE_DISPLAY, SSTATE
;
; Examples    :	See sunglobe_display.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Outputs     :	The various images are displayed in the graphics window
;
; Keywords    :	HOURGLASS = If set, then display an hourglass
;
; Calls       :	SUNGLOBE_PARSE_TMATRIX
;
; History     :	Version 1,  4-Jan-2016, William Thompson, GSFC
;               Version 2, 10-Apr-2019, WTT, add Connectivity Tool image
;               Version 3, 17-Aug-2021, WTT, add FOV paint image
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_display, sstate, hourglass=hourglass
;
if keyword_set(hourglass) then widget_control, /hourglass
;
;  Start off by removing the model from the view, and recreating the model.  Do
;  both the large and small versions to keep them in step.
;
sstate.opixview->remove, sstate.opixmodel
obj_destroy, sstate.opixmodel
sstate.opixmodel = obj_new('idlgrmodel')
sstate.opixview->add, sstate.opixmodel
;
sstate.opixview_small->remove, sstate.opixmodel_small
obj_destroy, sstate.opixmodel_small
sstate.opixmodel_small = obj_new('idlgrmodel')
sstate.opixview_small->add, sstate.opixmodel_small
;
;  Add the images to the model in reverse order.
;
for i = sstate.nmapped-1, 0, -1 do begin
    sstate.opixmodel->add, (*sstate.pimagestates[i]).omap_alpha, /alias
    sstate.opixmodel_small->add, (*sstate.pimagestates[i]).omap_alpha, /alias
endfor
;
;  Add the Magnetic Connectivity Tool image to the model.
;
if ptr_valid(sstate.pconnfile) then begin
    sstate.opixmodel->add, (*sstate.pconnfile).omap_alpha, /alias
    sstate.opixmodel_small->add, (*sstate.pconnfile).omap_alpha, /alias
endif
;
;  Add the painted FOV image to the model.
;
if ptr_valid(sstate.pfovpaint) then begin
    sstate.opixmodel->add, (*sstate.pfovpaint).omap_alpha, /alias
    sstate.opixmodel_small->add, (*sstate.pfovpaint).omap_alpha, /alias
endif
;
;  Draw the large version and read it out.
;
sstate.opixmap->draw, sstate.opixview
otempimage = sstate.opixmap->read()
otempimage->getproperty, data=tempimage
obj_destroy, otempimage
;
;  Update the globe and associated widget fields.
;
sstate.oimage->setproperty, data=temporary(tempimage)
sstate.owindow->draw, sstate.oview
sunglobe_parse_tmatrix, sstate
;
if keyword_set(hourglass) then widget_control, hourglass=0
end
