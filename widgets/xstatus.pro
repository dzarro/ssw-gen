;+
; Project     :	VSO
;
; Name        : xstatus
;
; Purpose     : Shows status of an operation
;
; Example     : xstatus,message
;
; Inputs :    : message = message to user
;
; Outputs     : None
;
; Keywords    : wbase = widget id of main status base
;               no_dismiss = inhibit dismiss button
;
; Written     :	Zarro (ADNET) 3 January 2010
;-

pro xstatus_main_event,  event                 

widget_control, event.id, get_uvalue = uservalue
widget_control, event.top, get_uvalue = info

if ~exist(uservalue) then uservalue=''
uservalue=trim(uservalue)

if uservalue eq 'dismiss' then xkill,event.top

;-- check timer event and update message to user

if uservalue eq 'timer' then begin
 if is_struct(info) then begin
  message=info.message
  space=info.space
  trails=info.trails
  tvalue=info.tvalue
  if tvalue eq 0 then new_tvalue=1
  if tvalue eq 1 then new_tvalue=0
  old_trail=trails[tvalue]
  new_trail=trails[new_tvalue]
  np=n_elements(message) 
  message[np-1]=message[np-1]+new_trail
  content=[space,message,space]
  info.tvalue=new_tvalue
  widget_control,event.top,set_uvalue=info
  widget_control,info.wtext,set_value=content
 endif
 widget_control,event.id, timer=.1
endif

return & end

;--------------------------------------------------------------------------- 

pro xstatus_main,message,group=group,instruct=instruct,title=title,$
            wbase=wbase,_extra=extra,no_dismiss=no_dismiss,space=space,kill=kill

if keyword_set(kill) then begin
 if xalive(wbase) then xkill,wbase else xkill,get_handler_id('xstatus_main')
 return
endif

if xregistered('xstatus_main') gt 0 then begin
 message,'Already running.',/cont
 return
endif

if is_blank(message) then message='Executing'
mk_dfont,bfont=bfont,tfont=tfont

if is_blank(title) then title ='Status'
if ~is_string(space,/blank) then space=''
wbase=widget_base(title=title,/column,group=group)
if is_blank(instruct) then instruct='Dismiss'

content=[space,message,space]
wtext=widget_text(wbase,value=content,font=tfont,xsize=max(strlen(message))+8,ysize=n_elements(content))

if ~keyword_set(no_dismiss) then begin
 wbase2=widget_base(wbase,/column,/align_center)
 c1=widget_base(wbase2,/row)
 dismissb=widget_button(c1,uvalue='dismiss',/no_release,font=bfont,$
                   /frame,value=instruct)
endif else wbase2=widget_base(wbase,map=0) 

;-- realize 

trail=['. . . .']
trails=[trail,' '+trail]

widget_control,wbase,$
 set_uvalue={wtext:wtext,message:message,trails:trails,tvalue:0,space:space}
xrealize,wbase,group=group,_extra=extra,/screen
widget_control,wbase2,set_uvalue='timer',timer=.1

xmanager,'xstatus_main',wbase,_extra=extra,/no_block

return & end

;---------------------------------------------------------------------------------

;-- kill background timer process

pro xstatus_kill,wbase,keep_bridge=keep_bridge

common xstatus,obridge
if ~obj_valid(obridge) then return
if obridge->status() then return
if exist(wbase) then obridge->setvar,"wbase",wbase
obridge->execute,"xkill,wbase"
if ~keyword_set(keep_bridge) then obj_destroy,obridge

return
end

;--------------------------------------------------------------------------

pro xstatus,message,_ref_extra=extra,background=background

if keyword_set(background) && since_version('6.3') then $
 thread,'xstatus_main',message,_extra=extra else $
  xstatus_main,message,_extra=extra
 
return & end
