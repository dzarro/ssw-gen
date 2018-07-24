;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_MAKE_IMAGE_WIDGETS
;
; Purpose     :	Make widgets for the various images read in
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : This routine makes empty widget bases for the various images
;               which are read in.  Each base resides within a higher-level
;               vertically scrollable base.  Within each base is a 64x64 icon,
;               a label, and a selection checkbox.  The bases start out
;               unmapped, and are revealed when populated with images.
;
; Syntax      :	SUNGLOBE_MAKE_IMAGE_WIDGETS, WBASE, WIMAGEBASES, PIMAGESTATES
;
; Examples    :	See sunglobe.pro
;
; Inputs      :	WBASE   = The widget ID of the vertically scrollable base
;                         containing all the image widgets.
;
; Opt. Inputs :	None
;
; Outputs     :	WIMAGEBASES  = A structure array containing the information
;                              about the widget bases.
;
;               PIMAGESTATES = A pointer array containing information about the
;                              images associated with the widget bases.
;                              Keeping this separate from the widget
;                              information allows the images to be easily
;                              reordered.
;
; Keywords    : MAXIMAGES = Maximum number of images which can be read in.
;                           Default is 1, since SUNGLOBE is now able to create
;                           spaces for new images on the fly.
;
; History     :	Version 1, William Thompson, 28-Dec-2015
;               Version 2, 5-Apr-2016, WTT, add RETAIN=2
;               Version 3, 18-Nov-2016, WTT, add keyword MAXIMAGES
;               Version 12, 02-Apr-2018, WTT, unbounded number of images
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_make_image_widgets, wbase, wimagebases, pimagestates, $
                                 maximages=maximages
;
;  Create separate widget bases for the individual images.
;
if n_elements(maximages) eq 0 then maximages = 1
wimagebases  = replicate({base: 0L, $
                          id: 0L, $
                          wdraw: 0L, $
                          wlabel: 0L}, maximages)
pimagestates = ptrarr(maximages)
;
for i=0,maximages-1 do begin
    wimagebases[i].base = $
      widget_base(wbase, /align_center, /column, /frame, map=0)
;
;  Put a 64x64 draw window at the top.
;
    wimagebases[i].wdraw = widget_draw(wimagebases[i].base, xsize=64, ysize=64, $
                                       retain=2)
;
;  Put a label under this.
;
    wimagebases[i].wlabel = widget_label(wimagebases[i].base, $
                                         value='xxx/yyyy/zzzz', /align_left)
    wimagebases[i].id = cw_bgroup(wimagebases[i].base, 'Select', $
                                  uvalue='SELECT', /nonexclusive, $
                                  set_value=0, /return_id)
;
;  Realize the widget.
;
    widget_control, wimagebases[i].base, /realize
endfor
;
;  Return the array of widget bases.
;
return
end
