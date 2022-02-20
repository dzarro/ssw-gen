;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SELECT_SPACECRAFT()
;
; Purpose     :	Select a spacecraft/planet viewpoint for the SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is called from SUNGLOBE_CHANGE_SPACECRAFT to
;               present a menu of possible spacecraft or planet viewpoints.
;               The user also has an option of typing in a body name or ID
;               code.  This option supports the selection of viewpoints beyond
;               what is normally available, so long as the appropriate SPICE
;               ephemerides are loaded, e.g. through the CSPICE_FURNSH command.
;
;               For example, if the file lovejoy.bsp contained an ephemeris for
;               Comet Lovejoy with the body ID of 1003162, then one would enter
;               CSPICE_FURNSH,'lovejoy.bsp' at the IDL command line.  This
;               ephemeris could then be selected by entering 1003162 into the
;               "Other" field.
;
;               If no ephemeris is available for the selected object, no error
;               is generated.  SunGlobe will simply not be able to set the
;               viewpoint when the "Ephemeris" option is selected.
;
; Syntax      :	SUNGLOBE_SELECT_SPACECRAFT, PSPACECRAFT, $
;                       GROUP_LEADER=GROUP_LEADER
;
; Examples    :	See sunglobe_get_fits.pro
;
; Input/Output:	PSPACECRAFT = Pointer to the currently selected viewpoint.
;
; Opt. I/O    :	None
;
; Keywords    : GROUP_LEADER = The widget ID of the group leader.  When this
;                              keyword points to a valid widget ID, this
;                              routine is run in modal mode.
;
; Calls       :	SUNGLOBE_SELECT_SPACECRAFT_EVENT, PARSE_SUNSPICE_NAME,
;               VALID_NUM, XANSWER, CSPICE_BODC2N
;
; Restrictions: None
;
; History     :	Version 1, William Thompson, 02-Apr-2019, GSFC
;               Version 2, 24-Dec-2019, WTT, make help modal
;               Version 3, 03-Mar-2020, WTT, exit if SunSPICE not loaded
;               Version 4, 25-Mar-2020, WTT, change "Exit" to "Select"
;
; Contact     :	WTHOMPSON
;-
;
;==============================================================================
;
;  Event handler for the SUNGLOBE_SELECT_SPACECRAFT widget program.
;
pro sunglobe_select_spacecraft_event, ev
;
;  Get the storage array.
;
widget_control, ev.top, get_uvalue=storage
;
;  Get the UVALUE, and act accordingly.
;
widget_control, ev.id, get_uvalue=uvalue
case uvalue of
    'EXIT': begin
        widget_control, ev.top, /destroy
        return
    end
;
;  The Reset button returns the widget to its original state.
;
    'RESET': begin
        *(storage.pspacecraft) = storage.spacecraft
        widget_control, ev.top, set_uvalue=storage
    end
;
;  One of the spacecraft was selected.
;
    'SPACECRAFT': begin
        *(storage.pspacecraft) = storage.sc_ids[ev.value]
        label = 'Current IDL: ' + ntrim(*(storage.pspacecraft))
        widget_control, storage.wlabel, set_value=label
        widget_control, ev.top, set_uvalue=storage
    end
;
;  One of the planets was selected.
;
    'PLANET': begin
        *(storage.pspacecraft) = storage.planet_ids[ev.value]
        label = 'Current IDL: ' + ntrim(*(storage.pspacecraft))
        widget_control, storage.wlabel, set_value=label
        widget_control, ev.top, set_uvalue=storage
    end
;
;  Something was entered into the "Other" field.  See if it can be translated
;  into something SunSPICE recognizes.  If not, then confirm whether or not the
;  user wants to continue.
;
    'OTHER': begin
        widget_control, ev.id, get_value=value
        value = ntrim(value[0])
	if value ne '' then begin
            id = parse_sunspice_name(value)
            if not valid_num(id) then begin	
                question = ['"' + value + '" not recognized.', $
                            'Do you want to continue?']
                if not xanswer(question) then return
            endif
            *(storage.pspacecraft) = id
            widget_control, storage.wother, set_value=''
        endif
    end
;
;  Bring up the help widget.
;
    'HELP': widg_help, 'sunglobe_select_spacecraft.hlp', /hierarchy, $
                       group_leader=ev.top, /no_block, /nofont, /modal
endcase
;
;  Set up the widget based on the current spacecraft ...
;
found = 0
value = intarr(n_elements(storage.sc_ids))
w = where(*(storage.pspacecraft) eq storage.sc_ids, count)
if count eq 1 then begin
    value[w] = 1
    found = 1
    widget_control, storage.wother, set_value=''
endif
widget_control, storage.wsc, set_value=value
;
;  ... or planet.
;
value = intarr(n_elements(storage.planet_ids))
w = where(*(storage.pspacecraft) eq storage.planet_ids, count)
if count eq 1 then begin
    value[w] = 1
    found = 1
    widget_control, storage.wother, set_value=''
endif
widget_control, storage.wplanet, set_value=value
;
;  Populate the label.
;
id = *(storage.pspacecraft)
if valid_num(id) then begin
    cspice_bodc2n, long(id), name, found
    if found then id = name
endif
if id eq 'SOLAR PROBE PLUS' then id = 'PARKER SOLAR PROBE'
label = 'Current viewpoint: ' + ntrim(id)
widget_control, storage.wlabel, set_value=label
;
end
;
;==============================================================================
;
pro sunglobe_select_spacecraft, pspacecraft, group_leader=group_leader
;
;  If the SunSPICE package isn't loaded, then exit with an error message.
;
which, 'load_sunspice', /quiet, outfile=temp
if temp eq '' then begin
    xack, 'Requires SunSPICE package'
    return
endif
;
;  Get the default spacecraft.
;
if not ptr_valid(pspacecraft) then pspacecraft = ptr_new('399')
spacecraft = *pspacecraft
;
;  Decide whether or not this should be a modal widget.
;
modal = 0
if n_elements(group_leader) eq 1 then $
  modal = widget_info(group_leader, /valid_id)
;
;  Set up the main base, and set up a base for the column lists.
;
wmain = widget_base(/column, group_leader=group_leader, modal=modal, $
                    title='SUNGLOBE_SELECT_SPACECRAFT')
wcol = widget_base(wmain, /row)
;
;  On the left side, set up a list of spacecraft that can be selected.
;
sc = ['Solar Orbiter', 'Parker Solar Probe', 'STEREO Ahead', 'STEREO Behind', $
      'SOHO']
sc_ids = ['-144', '-96', '-234', '-235', '-21']
wsc = cw_bgroup(wcol, sc, /column, /nonexclusive, label_top='Spacecraft', $
                uvalue='SPACECRAFT', /frame)
;
;  On the right side, set up a list of planets that can be selected.
;
planet = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', $
          'Neptune', 'Pluto']
planet_ids = ['199', '299', '399', '499', '5', '6', '7', '8', '9']
wplanet = cw_bgroup(wcol, planet, column=2, /nonexclusive, label_top='Planet', $
                    uvalue='PLANET', /frame)
;
;  Set up a text box for other possibilities.
;
wother = cw_field(wmain, /row, title='Other:', uvalue='OTHER', xsize=30, $
                  /return_events)
;
;  Show the current spacecraft ID.
;
id = *pspacecraft
if valid_num(id) then begin
    cspice_bodc2n, long(id), name, found
    if found then id = name
endif
if id eq 'SOLAR PROBE PLUS' then id = 'PARKER SOLAR PROBE'
label = 'Current viewpoint: ' + ntrim(id)
wlabel = widget_label(wmain, value=label, /dynamic_resize)
;
;  Set up the exit and reset buttons.
;
wdone = widget_base(wmain, /row)
dummy = widget_button(wdone, value='Select', uvalue='EXIT')
dummy = widget_button(wdone, value='Reset', uvalue='RESET')
dummy = widget_button(wdone, value='Help', uvalue='HELP')
;
;  Realize the widget
;
widget_control, wmain, /realize
;
;  Set up the widget based on the current spacecraft.
;
w = where(*pspacecraft eq sc_ids, count)
if count eq 1 then begin
    value = intarr(n_elements(sc_ids))
    value[w] = 1
    widget_control, wsc, set_value=value
end else begin
    w = where(*pspacecraft eq planet_ids, count)
    if count eq 1 then begin
        value = intarr(n_elements(planet_ids))
        value[w] = 1
        widget_control, wplanet, set_value=value
    endif
endelse
;
;  Set up the STORAGE structure, and store it in the top base.
;
storage = {pspacecraft: pspacecraft, $
           spacecraft: spacecraft, $
           wsc: wsc, $
           sc_ids: sc_ids, $
           wplanet: wplanet, $
           planet_ids: planet_ids, $
           wother: wother, $
           wlabel: wlabel}
widget_control, wmain, set_uvalue=storage
;
;  Start everything going.
;
xmanager, 'sunglobe_select_spacecraft', wmain, /no_block, $
  event_handler='sunglobe_select_spacecraft_event'
;
end
