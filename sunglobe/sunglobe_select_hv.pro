;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SELECT_HV()
;
; Purpose     :	Select an image via Helioviewer
;
; Category    :	Widget, Object Graphics, 3D, Planning
;
; Explanation :	This routine allows the user to select images from the
;               Helioviewer server based on a target date/time.  User is
;               presented with a selection menu organized by observatory,
;               instrument, and measurement.  For example, one may select
;               SDO as the observatory, AIA as the instrument, and 304
;               Angstroms as the measurement.  Once these parameters have been
;               selected, the user is presented with the time of the image
;               closest to the target time, and the time difference in days,
;               allowing the user to either proceed or cancel.
;
; Syntax      :	Source_ID = SUNGLOBE_SELECT_HV( DATE, LABEL=LABEL )
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	None required
;
; Opt. Inputs :	DATE    = The target date/time to search for.  If not passed,
;                         then the current time is used.
;
; Outputs     :	The output of the function is the Helioviewer source ID of the
;               selected observation.
;
; Opt. Outputs:	The keyword LABEL returns an optional label associated with the
;               selected measurement, e.g. "SDO/AIA/304".
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Calls       :	XACK, HV_SEARCH, XCALENDAR, ANYTIM2TAI, UTC2STR, UTC2TAI
;
; Common      :	None
;
; Restrictions:	At present, only full-disk images are supported.
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1,  4-Jan-2016, William Thompson, GSFC
;               Version 2, 22-Feb-2019, WTT, added IAS and ROB servers
;               Version 3, 12-Apr-2021, WTT, added Solar Orbiter EUI
;               Version 4, 30-Jul-2021, WTT, corrected AIA choices for ROB
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_select_hv_cleanup, tlb
;
;  Get the top-level UVALUE containing all the pointer IDs.
;
widget_control, tlb, get_uvalue=sstate, /no_copy
;
;  Free all pointers, except psource_id
;
ptr_free, sstate.pinstrument_text
ptr_free, sstate.pmeasurement_text
ptr_free, sstate.plabel_text
ptr_free, sstate.psource_ids
;
end

;------------------------------------------------------------------------------

pro sunglobe_select_hv_event, ev
;
;  If the window close box has been selected, then kill the widget.
;
if (tag_names(ev, /structure_name) eq 'WIDGET_KILL_REQUEST') then $
  goto, destroy
;
;  Get the current state structure.
;
widget_control, ev.top, get_uvalue=sstate, /no_copy
;
;  The server was selected.  Configure the observatory, instrument, and
;  measurement widgets based on the server.
;
widget_control, ev.id, get_uvalue=uvalue
case uvalue of
    'SERVER': begin
        sstate.observatory = ''
        *sstate.psource_id = -1
        widget_control, sstate.winstrument, set_value='Instrument', $
                        sensitive=0
        widget_control, sstate.wmeasurement, set_value='Measurement', $
                        sensitive=0
        *sstate.pobslabel  = ''
        *sstate.pinslabel  = ''
        *sstate.pmeaslabel = ''
;
;  If the server was reset, then reset the observatory widget.
;
        *sstate.pserver = sstate.server_text(ev.index)
        case *sstate.pserver of
            'Server': widget_control, sstate.wobservatory, sensitive=0, $
                                      set_value='Observatory'
;
;  GSFC was selected.  The possible observatories are SDO, STEREO-A, STEREO-B,
;  and PROBA2.
;
            'GSFC': begin
                observatory_text = $
                  ['Observatory', 'SDO', 'STEREO-A', 'STEREO-B', 'PROBA2']
                ptr_free, sstate.pobservatory_text
                sstate.pobservatory_text = ptr_new(observatory_text)
                widget_control, sstate.wobservatory, /sensitive, $
                                set_value=observatory_text, $
                                set_droplist_select=0
                widget_control, sstate.winstrument, sensitive=0, $
                                set_value='Instrument'
            end
;
;  IAS was selected.  The possible observatories are SDO, STEREO-A, STEREO-B,
;  and PROBA2.
;
            'IAS': begin
                observatory_text = $
                  ['Observatory', 'SDO', 'STEREO-A', 'STEREO-B', 'PROBA2']
                ptr_free, sstate.pobservatory_text
                sstate.pobservatory_text = ptr_new(observatory_text)
                widget_control, sstate.wobservatory, /sensitive, $
                                set_value=observatory_text, $
                                set_droplist_select=0
            end
;
;  ROB was selected.  The possible observatories are SDO, PROBA2, NSO, USET,
;  Kanzelhoehe, and Solar Orbiter
;
            'ROB': begin
                observatory_text =['Observatory', 'SDO', 'PROBA2', 'NSO', $
                                   'USET', 'Kanzelhoehe', 'Solar Orbiter']
                ptr_free, sstate.pobservatory_text
                sstate.pobservatory_text = ptr_new(observatory_text)
                widget_control, sstate.wobservatory, /sensitive, $
                                set_value=observatory_text, $
                                set_droplist_select=0
            end
        endcase
    end
;
;  The observatory was selected.  Configure the instrument and measurement
;  widgets based on the observatory.
;
    'OBSERVATORY': begin
        sstate.instrument = ''
        *sstate.psource_id = -1
;
;  If the observatory was reset, then reset the subsidiary widgets.
;
        sstate.observatory = (*sstate.pobservatory_text)[ev.index]
        case sstate.observatory of
            'Observatory': begin
                widget_control, sstate.winstrument, set_value='Instrument', $
                                sensitive=0
                widget_control, sstate.wmeasurement, set_value='Measurement', $
                                sensitive=0
                *sstate.pobslabel  = ''
                *sstate.pinslabel  = ''
                *sstate.pmeaslabel = ''
            end
;
;  SDO was selected.  The possible instruments are AIA and HMI.
;
            'SDO': begin
                instrument_text = ['Instrument', 'AIA', 'HMI']
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(instrument_text)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=instrument_text, set_droplist_select=0
                widget_control, sstate.wmeasurement, sensitive=0, $
                                set_value='Measurement'
                *sstate.pobslabel  = ''
                *sstate.pinslabel  = ''
                *sstate.pmeaslabel = ''
            end
;
;  STEREO-A was selected.  The only possible instrument is EUVI, and the
;  possible measurements are the wavelengths.
;
            'STEREO-A': begin
                sstate.instrument = 'EUVI'
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(sstate.instrument)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                measurement_text = ['Measurement', '171', '195', '284', '304']
                ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                sstate.pmeasurement_text = ptr_new(measurement_text)
                sstate.plabel_text = ptr_new(measurement_text)
                source_ids = [-1, 20, 21, 22, 23]
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(source_ids)
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=measurement_text, $
                                set_droplist_select=0
                *sstate.pobslabel  = 'STA/'
                *sstate.pinslabel  = 'EUVI/'
                *sstate.pmeaslabel = ''
            end
;
;  STEREO-B was selected.  The only possible instrument is EUVI, and the
;  possible measurements are the wavelengths.
;
            'STEREO-B': begin
                sstate.instrument = 'EUVI'
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(sstate.instrument)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                measurement_text = ['Measurement', '171', '195', '284', '304']
                ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                sstate.pmeasurement_text = ptr_new(measurement_text)
                sstate.plabel_text = ptr_new(measurement_text)
                source_ids = [-1, 24, 25, 26, 27]
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(source_ids)
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=measurement_text, $
                                set_droplist_select=0
                *sstate.pobslabel  = 'STB/'
                *sstate.pinslabel  = 'EUVI/'
                *sstate.pmeaslabel = ''
            end
;
;  PROBA2 was selected.  The only possible instrument is SWAP, and the only
;  possible measurement is 174.
;
            'PROBA2': begin
                sstate.instrument = 'SWAP'
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(sstate.instrument)
                ptr_free, sstate.pmeasurement_text
                sstate.pmeasurement_text = ptr_new('174')
                *sstate.psource_id = 32
                sstate.closest_date = ''
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(*sstate.psource_id)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=*sstate.pmeasurement_text
                *sstate.pobslabel  = ''
                *sstate.pinslabel  = 'SWAP/'
                *sstate.pmeaslabel = '174'
            end
;
;  NSO was selected.  The only possible instrument is GONG, and the only
;  possible measurement is magnetogram.
;
            'NSO': begin
                sstate.instrument = 'GONG'
                ptr_free, sstate.pmeasurement_text
                sstate.pmeasurement_text = ptr_new('Magnetogram')
                sstate.plabel_text = ptr_new(label_text)
                *sstate.psource_id = 37
                sstate.closest_date = ''
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(*sstate.psource_id)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=*sstate.pmeasurement_text
                *sstate.pobslabel  = ''
                *sstate.pinslabel = 'GONG/'
                *sstate.pmeaslabel = 'Mag'
            end
;
;  USET was selected.  The only possible instrument is H-alpha, and the only
;  possible measurement is H-alpha.
;
            'USET': begin
                sstate.instrument = 'H-alpha'
                ptr_free, sstate.pmeasurement_text
                sstate.pmeasurement_text = ptr_new('H-alpha')
                sstate.plabel_text = ptr_new(label_text)
                *sstate.psource_id = 47
                sstate.closest_date = ''
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(*sstate.psource_id)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=*sstate.pmeasurement_text
                *sstate.pobslabel  = ''
                *sstate.pinslabel = 'USET/'
                *sstate.pmeaslabel = 'H-alpha'
            end
;
;  Kanzelhoehe was selected.  The only possible instrument is H-alpha, and the
;  only possible measurement is H-alpha.
;
            'Kanzelhoehe': begin
                sstate.instrument = 'H-alpha'
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(sstate.instrument)
                ptr_free, sstate.pmeasurement_text
                sstate.pmeasurement_text = ptr_new('H-alpha')
                *sstate.psource_id = 50
                sstate.closest_date = ''
                ptr_free, sstate.psource_ids
                sstate.psource_ids = ptr_new(*sstate.psource_id)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=sstate.instrument
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=*sstate.pmeasurement_text
                *sstate.pobslabel  = ''
                *sstate.pinslabel  = 'Kanz/'
                *sstate.pmeaslabel = 'H-alpha'
            end
;
;  Solar Orbiter was selected.  The possible instruments are EUI/FSI and
;  EUI/HRI.
;
            'Solar Orbiter': begin
                instrument_text = ['Instrument', 'EUI/FSI', 'EUI/HRI']
                ptr_free, sstate.pinstrument_text
                sstate.pinstrument_text = ptr_new(instrument_text)
                widget_control, sstate.winstrument, /sensitive, $
                                set_value=instrument_text, set_droplist_select=0
                widget_control, sstate.wmeasurement, sensitive=0, $
                                set_value='Measurement'
                *sstate.pobslabel  = ''
                *sstate.pinslabel  = ''
                *sstate.pmeaslabel = ''
            end
        endcase
    end
;
;  The instrument was selected.
;
    'INSTRUMENT': begin
        sstate.instrument = (*sstate.pinstrument_text)[ev.index]
        *sstate.psource_id = -1
;
;  If the instrument was reset, then reset the measurement widget.
;
        if sstate.instrument eq 'Instrument' then begin
            widget_control, sstate.wmeasurement, sensitive=0, $
                            set_value='Measurement'
;
;  Otherwise, configure the measurement widget based on the instrument and the
;  previously selected observatory.
;
        end else case sstate.observatory of
            'SDO': case sstate.instrument of
;
;  SDO/AIA was selected.  The possible measurements are wavelengths.
;
                'AIA': begin
                    measurement_text = ['Measurement', '94', '131', '171', $
                                        '193', '211', '304', '335', '1600', $
                                        '1700', '4500']
                    source_ids = [-1, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
                    if *sstate.pserver eq 'ROB' then begin
                        measurement_text = ['Measurement', '171', '304']
                        source_ids = [-1, 10, 13]
                    endif
                    ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                    sstate.pmeasurement_text = ptr_new(measurement_text)
                    sstate.plabel_text = ptr_new(measurement_text)
                    ptr_free, sstate.psource_ids
                    sstate.psource_ids = ptr_new(source_ids)
                    *sstate.psource_id = -1
                    widget_control, sstate.wmeasurement, /sensitive, $
                                    set_value=measurement_text, $
                                    set_droplist_select=0
                    *sstate.pinslabel = 'AIA/'
                end
;
;  SDO/HMI was selected.  The possible measurements are intensity and
;  magnetogram.
;
                'HMI': begin
                    measurement_text = ['Measurement', 'Intensity', $
                                        'Magnetogram']
                    label_text = ['', 'Int','Mag']
                    ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                    sstate.pmeasurement_text = ptr_new(measurement_text)
                    sstate.plabel_text = ptr_new(label_text)
                    source_ids = [-1, 18, 19]
                    ptr_free, sstate.psource_ids
                    sstate.psource_ids = ptr_new(source_ids)
                    *sstate.psource_id = -1
                    widget_control, sstate.wmeasurement, /sensitive, $
                                    set_value=measurement_text, $
                                    set_droplist_select=0
                    *sstate.pinslabel = 'HMI/'
                end
            endcase
            'Solar Orbiter': case sstate.instrument of
;
;  EUI/FSI was selected.  The possible measurements are wavelengths.
;
                'EUI/FSI': begin
                    measurement_text = ['Measurement', '174', '304']
                    ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                    sstate.pmeasurement_text = ptr_new(measurement_text)
                    sstate.plabel_text = ptr_new(measurement_text)
                    source_ids = [-1, 1000, 1001]
                    ptr_free, sstate.psource_ids
                    sstate.psource_ids = ptr_new(source_ids)
                    *sstate.psource_id = -1
                    widget_control, sstate.wmeasurement, /sensitive, $
                                    set_value=measurement_text, $
                                    set_droplist_select=0
                    *sstate.pinslabel = 'EUI/FSI/'
                end
;
;  EUI/HRI was selected.  The possible measurements are wavelengths.
;
                'EUI/HRI': begin
                    measurement_text = ['Measurement', '174', '1216']
                    ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                    sstate.pmeasurement_text = ptr_new(measurement_text)
                    sstate.plabel_text = ptr_new(measurement_text)
                    source_ids = [-1, 1002, 1003]
                    ptr_free, sstate.psource_ids
                    sstate.psource_ids = ptr_new(source_ids)
                    *sstate.psource_id = -1
                    widget_control, sstate.wmeasurement, /sensitive, $
                                    set_value=measurement_text, $
                                    set_droplist_select=0
                    *sstate.pinslabel = 'EUI/HRI/'
                end
            endcase
;
;  No other observatory/instrument combinations require additional
;  configuration.
;
            else:
        endcase
    end
;
;  The measurement was selected.  Determine the source ID.
;
    'MEASUREMENT': begin
        new_id = (*sstate.psource_ids)[ev.index]
        if *sstate.psource_id ne new_id then sstate.closest_date = ''
        *sstate.psource_id = new_id
        *sstate.pmeaslabel = (*sstate.plabel_text)[ev.index]
    end
;
;  The date button was pressed.  Use XCALENDAR to change the date.
;
    'CHANGE': case ev.value of
        'DATE': begin
            date = *sstate.ptarget_date
            xcalendar, date, group=ev.top, /modal
            utc = anytim2utc(*sstate.ptarget_date)
            utc.mjd = (anytim2utc(date)).mjd
            *sstate.ptarget_date = utc2str(utc)
            widget_control, sstate.wtarget, set_value=*sstate.ptarget_date
            sstate.closest_date = ''
        end
;
;  The time button was pressed.  Use XTIME to change the time.
;
        'TIME': begin
            date = *sstate.ptarget_date
            xtime, date, group=ev.top, /modal
            utc = anytim2utc(*sstate.ptarget_date)
            utc.time = (anytim2utc(date)).time
            *sstate.ptarget_date = utc2str(utc)
            widget_control, sstate.wtarget, set_value=*sstate.ptarget_date
            sstate.closest_date = ''
        end
    endcase
;
;  If the cancel button was pressed, then reset the source ID.
;
    'CANCEL': begin
        text = 'Are you sure you want to cancel this selection?'
        if xanswer(text) then begin
            *sstate.psource_id = -1
            *sstate.pobslabel  = ''
            *sstate.pinslabel  = ''
            *sstate.pmeaslabel = ''
            goto, destroy
        endif
    end
;
;  If the exit button was pressed, then return the source ID.
;
    'EXIT': begin
        if sstate.closest_date eq '' then ndays = 0 else $
          ndays = abs(anytim2tai(sstate.closest_date) - $
                      utc2tai(*sstate.ptarget_date)) / 86400
        if ndays gt 30 then begin
            text = ['Data are ' + ntrim(ndays) + ' days away from target date.', $
                    'Are you sure you want to continue?']
            destroy = xanswer(text)
        end else destroy = 1
        if destroy then begin
destroy:
            widget_control, ev.top, set_uvalue=sstate, /no_copy
            widget_control, ev.top, /destroy
            return
        endif
    end
;
;  Handle all other events.
;
    else:                       ;Do nothing
endcase
;
;  Display the value of the source ID.
;
widget_control, sstate.wsource_id, set_value=*sstate.psource_id
;
;  If the source ID is -1, then reset the closest date field.
;
if *sstate.psource_id eq -1 then begin
    sstate.closest_date = ''
    widget_control, sstate.wdate, set_value=sstate.closest_date
    widget_control, sstate.wndays, set_value=''
endif
;
;  If not already done, determine the closest date.
;
if (sstate.closest_date eq '') and (*sstate.psource_id ge 0) then begin
    ias = *sstate.pserver eq 'IAS'
    rob = *sstate.pserver eq 'ROB'
    info = hv_search(*sstate.ptarget_date, *sstate.psource_id, ias=ias, rob=rob)
    if datatype(info) eq 'STC' then begin
        sstate.closest_date = info.date
        heap_free, info
        widget_control, sstate.wdate, set_value=sstate.closest_date
        ndays = abs(anytim2tai(sstate.closest_date) - $
                    utc2tai(*sstate.ptarget_date)) / 86400
        widget_control, sstate.wndays, set_value=string(ndays,format='(F8.2)')
    end else xack, 'Unable to get closest date from server'
endif
;
;  The exit button is only active when the source ID is valid.
;
sensitive = *sstate.psource_id ge 0
widget_control, sstate.wexit, sensitive=sensitive
;
;  Store the current state structure.
;
widget_control, ev.top, set_uvalue=sstate, /no_copy
end

;------------------------------------------------------------------------------

function sunglobe_select_hv, date, group_leader=group_leader, label=label, $
                             server=server, _extra=_extra
;
if n_elements(date) eq 0 then get_utc, target_date, /ccsds else begin
    errmsg = ''
    target_date = anytim2utc(date, /ccsds, errmsg=errmsg, _extra=_extra)
    if errmsg ne '' then begin
        xack, errmsg
        return, -1
    endif
endelse
;
;  Decide whether or not this should be a modal widget.
;
modal = 0
if n_elements(group_leader) eq 1 then $
  modal = widget_info(group_leader, /valid_id)
;
;  Set up the top base as a column widget.
;
wtopbase = widget_base(/column, group_leader=group_leader, modal=modal)
title = widget_label(wtopbase, value='Select Helioviewer image')
;
;  Set up the dropbox widgets for the observatory, instrument, and measurement.
;
server_text = ['Server', 'GSFC', 'IAS', 'ROB']
wserver = widget_droplist(wtopbase, value=server_text, uvalue='SERVER')
wobservatory = widget_droplist(wtopbase, value='Observatory', sensitive=0, $
                               uvalue='OBSERVATORY')
winstrument = widget_droplist(wtopbase, value='Instrument', sensitive=0, $
                              uvalue='INSTRUMENT')
wmeasurement = widget_droplist(wtopbase, value='Measurement', sensitive=0, $
                               uvalue='MEASUREMENT')
;
;  Set up a field to contain the target date, and for controls to change the
;  date and time.
;
wtarget = cw_field(wtopbase, title='Target date', /column, value=target_date, $
                   /noedit)
wchange = widget_base(wtopbase, /row)
dummy = widget_label(wchange, value='Change')
dummy = cw_bgroup(wchange, ['Date', 'Time'], /ROW, uvalue='CHANGE', $
                  button_uvalue=['DATE','TIME'])
;
;  Set up a field to contain the source ID.
;
wsource_id = cw_field(wtopbase, title='SourceID:', /row, value=-1, xsize=3, $
                   /noedit)
;
;  Set up fields to contain the date of the closest file, and the difference in
;  days from the target date.
;
wdate = cw_field(wtopbase, title='Closest date', /column, value=target_date, $
                 /noedit)
wndays = cw_field(wtopbase, title='#days:', /row, value='', /noedit, xsize=8)
;
;  Set up cancel and exit buttons.
;
wbuttonbase = widget_base(wtopbase, /row)
dummy = widget_button(wbuttonbase, value='Cancel', uvalue='CANCEL')
wexit = widget_button(wbuttonbase, value='Select', uvalue='EXIT', sensitive=0)
;
;  Realize the widget hierarchy.
;
widget_control, wtopbase, /realize
widget_control, wdate, set_value=''
;
;  Set up pointers for the source ID and label information.  This allows these
;  to be returned by the widget.
;
pserver    = ptr_new('')
psource_id = ptr_new(-1)
pobslabel  = ptr_new('')
pinslabel  = ptr_new('')
pmeaslabel = ptr_new('')
ptarget_date = ptr_new(target_date)
;
;  Define the state structure, and store it in the top base.
;
sstate = {wtopbase: wtopbase, $
          wobservatory: wobservatory, $
          winstrument: winstrument, $
          wmeasurement: wmeasurement, $
          wtarget: wtarget, $
          wsource_id: wsource_id, $
          wdate: wdate, $
          wndays: wndays, $
          wexit: wexit, $
          server_text: server_text, $
          pobservatory_text: ptr_new(), $
          pinstrument_text: ptr_new(), $
          pmeasurement_text: ptr_new(), $
          plabel_text: ptr_new(), $
          pserver: pserver, $
          observatory: '', $
          instrument: '', $
          ptarget_date: ptarget_date, $
          closest_date: '', $
          psource_ids: ptr_new(), $
          psource_id: psource_id, $
          pobslabel: pobslabel, $
          pinslabel: pinslabel, $
          pmeaslabel: pmeaslabel}
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_select_hv', wtopbase, $
          event_handler='sunglobe_select_hv_event', $
          cleanup='sunglobe_select_hv_cleanup'
;
;  Extract the result, free the pointer, and return.
;
server = *pserver
source_id = *psource_id
label = *pobslabel + *pinslabel + *pmeaslabel
date = *ptarget_date
ptr_free, psource_id, pobslabel, pinslabel, pmeaslabel, ptarget_date
return, source_id
;
end
