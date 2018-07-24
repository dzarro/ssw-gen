;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_ADD_IMAGE_WIDGET
;
; Purpose     :	Make widgets for the various images read in
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : This routine adds an empty widget base for an images which are
;               read in.  Each base resides within a higher-level vertically
;               scrollable base.  Within each base is a 64x64 icon, a label,
;               and a selection checkbox.  The bases start out unmapped, and
;               are revealed when populated with images.
;
; Syntax      :	SUNGLOBE_ADD_IMAGE_WIDGET, WBASE, WIMAGEBASES, PIMAGESTATES
;
; Examples    :	See sunglobe.pro
;
; Inputs      :	SSTATE  = Widget top-level state structure
;
; Keywords    : None.
;
; History     :	Version 1, William Thompson, 02-Mar-2018
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_add_image_widget, sstate
;
;  Create separate widget bases for the individual images.
;
i = n_elements(sstate.wimagebases)
wimagebases  = [sstate.wimagebases, {base: 0L, $
                                     id: 0L, $
                                     wdraw: 0L, $
                                     wlabel: 0L}]
pimagestates = [sstate.pimagestates, ptrarr(1)]
;
wimagebases[i].base = widget_base(sstate.wrightbase, /align_center, /column, $
                                  /frame, map=0)
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
;  Replace the tags in the sstate structure.
;
sstate = rem_tag(sstate, ['WIMAGEBASES', 'PIMAGESTATES'])
sstate = add_tag(sstate, wimagebases, 'WIMAGEBASES')
sstate = add_tag(sstate, pimagestates, 'PIMAGESTATES')
;
;  Realize the widget.
;
widget_control, wimagebases[i].base, /realize
;
;  Return the updated array of widget bases.
;
return
end
