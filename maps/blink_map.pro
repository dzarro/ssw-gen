;+
; Project     : SOHO-CDS
;
; Name        : BLINK_MAP
;
; Purpose     : blink two maps using XINTERANIMATE
;
; Category    : imaging
;
; Syntax      : blink_map,map1,map2,_extra=extra
;
; Inputs      : MAP1,MAP2 = image map structures
;
; Keywords    : same as PLOT_MAP
;               PLOT1 (structure) = keywords specific to first map
;               PLOT2 (structure) = keywords specific to second map
;
; Restrictions: First map is used to set plotting scale
;               Have to be careful setting keywords.
;               For example, to plot the first map on a linear scale
;               and the second on a log use:
;                IDL> blink_map,m1,m2,plot1={log:0},plot2={log:1}
;
; History     : Written 4 Jan 1999, D. Zarro, SMA/GSFC
;               22-May-2016, Zarro (ADNET) - added PLOT1,2 keywords
;
; Contact     : dzarro@solar.stanford.edu
;-

pro blink_map,map1,map2,_extra=extra,plot1=plot1,plot2=plot2

if ~valid_map(map1) || ~valid_map(map2) then begin
 pr_syntax,'blink_map,map1,map2'
 return
endif

;-- first kill old processes

xkill,'xinteranimate'

;-- plot first map

if is_struct(extra) || is_struct(plot1) then extra1=join_struct(extra,plot1)
plot_map,map1,_extra=extra1

last_window=!d.window

;-- load into pixmap and plot second map

xinteranimate,set=[!d.x_size,!d.y_size,2]

xinteranimate,window=last_window,frame=0

if is_struct(extra) || is_struct(plot2) then extra2=join_struct(extra,plot2)
plot_map,map2,_extra=extra2,fov=map1

xinteranimate,window=last_window,frame=1

xinteranimate

return & end


