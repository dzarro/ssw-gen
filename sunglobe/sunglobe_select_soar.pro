;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SELECT_SOAR()
;
; Purpose     :	Select a FITS file from Solar Orbiter archive
;
; Category    :	Widget, Object Graphics, 3D, Planning
;
; Explanation : This routine allows the user to select FITS files from the
;               Solar Orbiter SOAR archive based on a target date/time.  User
;               is presented with a selection menu organized by instrument and
;               measurement.  For example, one may select EUI as the instrument
;               and FSI 304 Angstroms as the measurement.  Once these
;               parameters have been selected, the user is presented with the
;               time of the image closest to the target time, and the time
;               difference in days, allowing the user to either proceed or
;               cancel.
;
; Syntax      :	Source_ID = SUNGLOBE_SELECT_SOAR( DATE, LABEL=LABEL )
;
; Examples    :	See sunglobe_event.pro
;
; Inputs      :	None required
;
; Opt. Inputs :	DATE    = The target date/time to search for.  If not passed,
;                         then the current time is used.
;
; Outputs     :	The output of the function is a structure describing the FITS
;               file on the archive, which can be passed to SOAR_GET().
;
; Opt. Outputs:	The keyword LABEL returns an optional label associated with the
;               selected measurement, e.g. "EUI/FSI/304".
;
; Keywords    :	GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Calls       :	XACK, SOAR_SEARCH, XCALENDAR, ANYTIM2TAI, UTC2STR, UTC2TAI
;
; Common      :	None
;
; Restrictions:	At present, only EUI is supported.
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 21-Jan-2021, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;

;------------------------------------------------------------------------------

pro sunglobe_select_soar_cleanup, tlb
;
;  Get the top-level UVALUE containing all the pointer IDs.
;
widget_control, tlb, get_uvalue=sstate, /no_copy
;
;  Free all pointers, except those needed at end of SUNGLOBE_SELECT_SOAR
;
ptr_free, sstate.pmeasurement_text
ptr_free, sstate.plabel_text
ptr_free, sstate.pinstrument
;
end

;------------------------------------------------------------------------------

pro sunglobe_select_soar_event, ev
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
;  The instrument was selected.  Configure the measurement widget based on the
;  instrument.
;
widget_control, ev.id, get_uvalue=uvalue
case uvalue of
    'INSTRUMENT': begin
        *sstate.pinstrument = (sstate.instrument_text)[ev.index]
        ptr_free, (*sstate.presult).pdescription
        (*sstate.presult).pdescription = ptr_new(-1)
        sstate.search_text = 'No search'
;
;  If the instrument was reset, then reset the measurement widget.
;
        if *sstate.pinstrument eq 'Instrument' then begin
            widget_control, sstate.wmeasurement, sensitive=0, $
                            set_value='Measurement'
;
;  Otherwise, configure the measurement widget based on the instrument.
;
        end else case *sstate.pinstrument of
;
;  EUI was selected.  The possible measurements are FSI vs. HRI, and
;  wavelengths/filters.
;
            'EUI': begin
                measurement_text = ['Measurement', 'Any', 'FSI 174', $
                                    'FSI 304', 'HRI EUV 174', 'HRI EUV Open', $
                                    'HRI Lyman Alpha 1216']
                measurement_label = ['', 'Any', 'FSI/174', 'FSI/304', $
                                     'HRI/174', 'HRI/Open', 'HRI/LyA']
                ptr_free, sstate.pmeasurement_text, sstate.plabel_text
                sstate.pmeasurement_text = ptr_new(measurement_text)
                sstate.plabel_text = ptr_new(measurement_label)
                search_texts = ['No search', '', 'fsi174', 'fsi304', $
                                'hrieuv174', 'hrieuvnon', 'hrilya1216']
                ptr_free, sstate.psearch_texts
                sstate.psearch_texts = ptr_new(search_texts)
                ptr_free, (*sstate.presult).pdescription
                (*sstate.presult).pdescription = ptr_new(-1)
                widget_control, sstate.wmeasurement, /sensitive, $
                                set_value=measurement_text, $
                                set_droplist_select=0
                *sstate.pinslabel = 'EUI/'
            end
            else:
        endcase
    end
;
;  The measurement was selected.  Determine the search text.
;
    'MEASUREMENT': begin
        sstate.search_text = (*sstate.psearch_texts)[ev.index]
        sstate.closest_date = ''
        (*sstate.presult).pdescription = ptr_new(-1)
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
;  If the cancel button was pressed, then reset the result.
;
    'CANCEL': begin
        text = 'Are you sure you want to cancel this selection?'
        if xanswer(text) then begin
            ptr_free, (*sstate.presult).pdescription
            (*sstate.presult).pdescription = ptr_new(-1)
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
;  If the result is not a structure, then reset the closest date field.
;
description = *((*sstate.presult).pdescription)
if datatype(description) ne 'STC' then begin
    sstate.closest_date = ''
    widget_control, sstate.wdate, set_value=sstate.closest_date
    widget_control, sstate.wndays, set_value=''
endif
;
;  If the search text is the null string, then do a search of the SOAR archive.
;
if sstate.search_text ne 'No search' then begin
   low_latency = 0
do_search:
   widget_control, /hourglass
   info = soar_search(*sstate.ptarget_date, *sstate.pinstrument, $
                      search=sstate.search_text, max_days=5, $
                      low_latency=low_latency)
   widget_control, hourglass=0
   if datatype(info) eq 'STC' then begin
      description = info
      (*sstate.presult).pdescription = ptr_new(info)
   end else begin
;
;  If the first search didn't find anything, try low latency.
;
      if low_latency eq 0 then begin
         low_latency = 1
         goto, do_search
      endif
      xack, 'No file found matching search criteria'
   endelse
endif
;
;  If not already done, determine the closest date.
;
if (sstate.closest_date eq '') and (datatype(description) eq 'STC') $
then begin
    sstate.closest_date = description.begin_time
    widget_control, sstate.wdate, set_value=sstate.closest_date
    ndays = abs(anytim2tai(sstate.closest_date) - $
                utc2tai(*sstate.ptarget_date)) / 86400
    widget_control, sstate.wndays, set_value=string(ndays,format='(F8.2)')
endif
;
;  The exit button is only active when the file result is valid.
;
sensitive = datatype(description) ge 'STC'
widget_control, sstate.wexit, sensitive=sensitive
;
;  Store the current state structure.
;
widget_control, ev.top, set_uvalue=sstate, /no_copy
end

;------------------------------------------------------------------------------

function sunglobe_select_soar, date, group_leader=group_leader, label=label, $
                               _extra=_extra
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
title = widget_label(wtopbase, value='Select Solar Orbiter FITS file')
;
;  Set up the dropbox widget for the instrument and measurement.
;
instrument_text = ['Instrument', 'EUI']
winstrument = widget_droplist(wtopbase, value=instrument_text, $
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
;  Set up pointers for the label information.  This allows these
;  to be returned by the widget.
;
pinstrument = ptr_new('')
presult = ptr_new({pdescription: ptr_new(-1)})
pinslabel  = ptr_new('')
pmeaslabel = ptr_new('')
ptarget_date = ptr_new(target_date)
;
;  Define the state structure, and store it in the top base.
;
sstate = {wtopbase: wtopbase, $
          winstrument: winstrument, $
          wmeasurement: wmeasurement, $
          wtarget: wtarget, $
          wdate: wdate, $
          wndays: wndays, $
          wexit: wexit, $
          instrument_text: instrument_text, $
          pmeasurement_text: ptr_new(), $
          plabel_text: ptr_new(), $
          pinstrument: pinstrument, $
          ptarget_date: ptarget_date, $
          closest_date: '', $
          psearch_texts: ptr_new(), $
          search_text: 'No search', $
          presult: presult, $
          pinslabel: pinslabel, $
          pmeaslabel: pmeaslabel}
widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
;  Start the whole thing going.
;
xmanager, 'sunglobe_select_soar', wtopbase, $
          event_handler='sunglobe_select_soar_event', $
          cleanup='sunglobe_select_soar_cleanup'
;
;  Extract the result, free the pointers, and return.
;
result = *presult
pdescription = result.pdescription
description = *pdescription
label = *pinslabel + *pmeaslabel
date = *ptarget_date
ptr_free, presult, pdescription, pinslabel, pmeaslabel, ptarget_date
return, description
;
end
