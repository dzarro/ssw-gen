;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_LOAD_EPHEM
;
; Purpose     :	Load orbiter ephemeris files for SUNGLOBE program
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine is a temporary placeholder to load some test
;               ephemeris files for Solar Orbiter.  It calls LOAD_SUNSPICE_GEN
;               to get a usable set of ephemeris files loaded, and then loads a
;               sample ephemeris file for Orbiter.  If available, this is done
;               through LOAD_SUNSPICE_SOLO.
;
; Syntax      :	SUNGLOBE_LOAD_EPHEM, SPACECRAFT
;
; Examples    :	See sunglobe.pro
;
; Inputs      : SPACECRAFT = SPICE ID of spacecraft whose ephemerides
;                            should be loaded.
;
; Opt. Inputs :	None
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	WHICH, FIND_WITH_DEF, LIST_SUNSPICE_KERNELS, LOAD_SUNSPICE_GEN,
;               LOAD_SUNSPICE
;
; Common      :	None
;
; Restrictions:	The Orbiter kernel file must be in the current directory.
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 7-Jan-2016, William Thompson, GSFC
;               Version 2, 4-Aug-2016, WTT, use SUNSPICE package
;                       Remove outputs MINDATE, MAXDATE
;                       Renamed to SUNGLOBE_LOAD_EPHEM
;               Version 3, 26-Aug-2016, WTT, use SPACECRAFT parameter
;               Version 4, 18-Nov-2016, WTT, call FIND_WITH_DEF
;                                            check if SunSPICE is loaded
;               Version 5, 28-Jul-2017, WTT, check for LOAD_SUNSPICE_SOLO
;                                            call ADD_SUNSPICE_MISSION
;                                            Use February ephemeris
;               Version 6, 10-Apr-2019, WTT, Use Feb 2020 ephemeris
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_load_ephem, spacecraft
;
;  If the SunSPICE package has not been loaded, then simply return.
;
which, 'load_sunspice', /quiet, outfile=temp
if temp eq '' then return
;
;  For the present, treat Solar Orbiter as a special case.
;
add_sunspice_mission, spacecraft
which, 'load_sunspice_solo', /quiet, outfile=temp
if (spacecraft eq '-144') and (temp eq '') then begin
;
;  Check to see if the Orbiter ephemeris has already been loaded.
;
    filename = find_with_def('2020_February_In_CReMA_Issue4-0.bsp', !path)
    list_sunspice_kernels, kernels=kernels, /quiet
    if n_elements(kernels) gt 0 then w=where(kernels eq filename, count) else $
      count=0
;
;  If not already loaded, then load the spice kernels.
;
    if count eq 0 then begin
        load_sunspice_gen
        cspice_furnsh, filename
    endif
;
;  Otherwise, simply use SunSPICE to load the kernels.
;
end else load_sunspice, spacecraft
;
end
