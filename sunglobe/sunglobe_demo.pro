;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_DEMO
;
; Purpose     :	Demonstration of passing SUNGLOBE events back and forth
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This is a demonstration program showing how events can be
;               passed back and forth between SUNGLOBE and another widget
;               program.
;
;               A change in the target date can be sent as an event to SUNGLOBE
;               by forming an event structure with the tags:
;
;               ev = {id: 0L, top: 0L, handler: 0L, target_date: date}
;
;               and setting the UVALUE to 'EVENT_TARGET_DATE'.
;
;               SUNGLOBE can send back an event with a UVALUE of
;               'SUNGLOBE_POINTING', and the pointing values are embedded in
;               the event structure with the tags .xsc and .ysc.
;
; Syntax      :	SUNGLOBE_DEMO
;
; Examples    :	SUNGLOBE_DEMO
;               SUNGLOBE_DEMO, '2012-11-23 15:38', TEST=10
;
; Inputs      :	None required
;
; Opt. Inputs :	TARGET_DATE = The target date/time for selecting images.  If not
;                             passed, the present date/time is used.
;
; Keywords    :	TEST_OFFSET = Number of years to offset from the current date
;                             to make it look like Orbiter has already
;                             launched for ephemeris purposes.  For example,
;                             setting TEST_OFFSET=8 will treat dates in 2016 as
;                             if they were 2024 when referencing the ephemeris.
;
; Calls       :	SUNGLOBE, XCALENDAR, XTIME, ANYTIM2UTC, UTC2STR
;
; History     :	Version 1, 15-Jan-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_demo_event, event
;
widget_control, event.id, get_uvalue=uvalue
widget_control, event.top, get_uvalue=sstate
case uvalue of
    'SUNGLOBE': begin
        widget_control, sstate.wtarget, get_value=target_date
        sunglobe, target_date, group_leader=event.top, $
                  sendbase=sunglobe_base, returnid=sstate.wscpoint, $
                  test_offset=sstate.test_offset
        sstate.sunglobe_base = sunglobe_base
    end
;
;  The date button was pressed.  Use XCALENDAR to change the date.
;
    'CHANGE': case event.value of
        'DATE': begin
            widget_control, sstate.wtarget, get_value=target_date
            date = target_date
            xcalendar, date, group=event.top, /modal
            utc = anytim2utc(target_date)
            utc.mjd = (anytim2utc(date)).mjd
            target_date = utc2str(utc)
            widget_control, sstate.wtarget, set_value=target_date
            if widget_info(sstate.sunglobe_base, /valid_id) then begin
                send_event = {id: 0L, top: 0L, handler: 0L, $
                              target_date: target_date}
                widget_control, sstate.sunglobe_base, send_event=send_event, $
                                set_uvalue='EVENT_TARGET_DATE'
            endif
        end
;
;  The time button was pressed.  Use XTIME to change the time.
;
        'TIME': begin
            widget_control, sstate.wtarget, get_value=target_date
            date = target_date
            xtime, date, group=event.top, /modal
            utc = anytim2utc(target_date)
            utc.time = (anytim2utc(date)).time
            target_date = utc2str(utc)
            widget_control, sstate.wtarget, set_value=target_date
            if widget_info(sstate.sunglobe_base, /valid_id) then begin
                send_event = {id: 0L, top: 0L, handler: 0L, $
                              target_date: target_date}
                widget_control, sstate.sunglobe_base, send_event=send_event, $
                                set_uvalue='EVENT_TARGET_DATE'
            endif
        end
    endcase
;
;  Pointing values have been sent from SUNGLOBE.
;
    'SUNGLOBE_POINTING': begin
        widget_control, sstate.wxsc, set_value=event.xsc
        widget_control, sstate.wysc, set_value=event.ysc
    end
;
    else:                       ;Do nothing
endcase
widget_control, event.top, set_uvalue=sstate
end

;------------------------------------------------------------------------------

pro sunglobe_demo, date, test_offset=test_offset
;
;  Check the validity of the target date.
;
if n_elements(date) eq 0 then get_utc, target_date, /ccsds else begin
    errmsg = ''
    target_date = anytim2utc(date, /ccsds, errmsg=errmsg)
    if errmsg ne '' then message, errmsg
endelse
;
if n_elements(test_offset) eq 0 then test_offset=0
;
wtopbase = widget_base(/column)
dummy = widget_button(wtopbase, value='Call SUNGLOBE', uvalue='SUNGLOBE')
;
wtarget = cw_field(wtopbase, title='Target date', /column, value=target_date, $
                   /noedit)
wchange = widget_base(wtopbase, /row)
dummy = widget_label(wchange, value='Change')
dummy = cw_bgroup(wchange, ['Date', 'Time'], /ROW, uvalue='CHANGE', $
                  button_uvalue=['DATE','TIME'])
;
dummy = widget_label(wtopbase, value='Spacecraft pointing (arcsec)')
wscpoint = widget_base(wtopbase, /align_center, /row)
xsc = 0.0
wxsc = cw_field(wscpoint, /frame, /row, value=xsc, title="X", /float, xsize=9)
ysc = 0.0
wysc = cw_field(wscpoint, /frame, /row, value=ysc, title="Y", /float, xsize=9)
;
;  Realize the widget hierarchy.
;
widget_control, wtopbase, /realize
;
;  Define the state structure, and store it in the top base.
;
sstate = {wtopbase: wtopbase, $
          test_offset: test_offset, $
          sunglobe_base: -1L, $
          wscpoint: wscpoint, $
          wxsc: wxsc, $
          wysc: wysc, $
          wtarget: wtarget}
widget_control, wtopbase, set_uvalue=sstate
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_demo', wtopbase, /no_block
;
end
