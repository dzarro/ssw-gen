;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_PFSS__DEFINE
;
; Purpose     :	Object graphics for PFSS magnetic field lines in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : Called from SUNGLOBE_GET_PFSS to read in a potential field
;               source surface (PFSS) magnetic model, and generate a set of
;               polyline objects representing the magnetic field lines.
;
; Syntax      :	To initially create:
;                       oPFSS = OBJ_NEW('sunglobe_pfss', sstate=sstate)
;
;               To retrieve a property value:
;                       oPFSS -> GetProperty, property=property
;
;               To set a property value:
;                       oPFSS -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oPFSS -> build
;
;               To update the differential rotation correction:
;                       oPFSS -> diffrot, date
;
;               To destroy:
;                       OBJ_DESTROY, oPFSS
;
; Examples    :	See sunglobe_get_pfss.pro, sunglobe_change_date.pro
;
; Keywords    :	The following keyword is required when initializing the object.
;
;               SSTATE  = Widget top-level state structure
;
;               The following keywords pertain to the INIT, GETPROPERTY, and
;               SETPROPERTY methods.
;
;               NLINES  = Target number of magnetic field lines (Default=300)
;
;               FIELDTYPE = Field type parameter.  (Default=6)
;
;               EXZONE  = Polar exclusion zone: number of degrees around each
;                         pole to exclude from the starting points.  Used
;                         mainly with FIELDTYPE=6 to prevent the coronal polar
;                         holes from dominating the calculation.  (Default=0)
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Common      : Uses @PFSS_DATA_BLOCK to communicate with PFSS software.
;
; Restrictions: Must have SolarSoft PFSS tree loaded.
;
; Calls       :	SUNGLOBE_PFSS::BUILD, DATATYPE, ANYTIM2TAI, UTC2TAI, DIFF_ROT,
;               PFSS_TIME2FILE, PFSS_RESTORE, PFSS_FIELD_START_COORD,
;               PFSS_TRACE_FIELD, GET_INTERPOLATION_INDEX
;
; History     :	Version 1, 08-Feb-2016, William Thompson, GSFC
;               Version 2, 09-Feb-2018, WTT, use RADSTART to improve results
;               Version 3, 20-Mar-2018, WTT, added EXZONE keyword
;               Version 4, 10-Apr-2019, WTT, fix pointer free bug
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_pfss::init, sstate=sstate, nlines=nlines, $
                              fieldtype=fieldtype, exzone=exzone, _extra=_extra
;
;  Can't initialize the object without an sstate array.
;
if datatype(sstate) ne 'STC' then begin
    print, 'SSTATE is not a structure'
    return, 0
endif
;
;  Initialize the graphics model containing the PFSS description.
;
if (self->idlgrmodel::init(_extra=_extra) ne 1) then begin
    print, 'Unable to initiate structure'
    return, 0
endif
;
;  Store the input parameters into the object.
;
self.psstate = ptr_new(sstate)  ;Widget state structure
self.nlines = 300               ;Target number of field lines
self.fieldtype = 6              ;Type specification for field line generation
self.exzone = 0.0               ;Polar exclusion zone.

if n_elements(nlines) eq 1 then self.nlines = nlines
if n_elements(fieldtype) eq 1 then self.fieldtype = fieldtype
if n_elements(exzone) eq 1 then self.exzone = exzone
;
;  Build the PFSS graphics based on the input properties.
;
self->build
;
return, 1
end

;------------------------------------------------------------------------------

pro sunglobe_pfss::setproperty, sstate=sstate, nlines=nlines, $
                                fieldtype=fieldtype, exzone=exzone, $
                                _extra=_extra
;
self->idlgrmodel::setproperty, _extra=_extra
for i=0,self.npt-1 do ((*self.polines)[i])->setproperty, _extra=_extra
;
rebuild = 0
if datatype(sstate) eq 'STC' then begin
    ptr_free, self.psstate
    self.psstate = ptr_new(sstate)
    rebuild = 1
endif
if n_elements(nlines) eq 1 then begin
    self.nlines = nlines
    rebuild = 1
endif
if n_elements(fieldtype) eq 1 then begin
    self.fieldtype = fieldtype
    rebuild = 1
endif
if n_elements(exzone) eq 1 then begin
    self.exzone = exzone
    rebuild = 1
endif
;
;  Build the PFSS graphics based on the input properties.
;
if rebuild then self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_pfss::getproperty, sstate=sstate, nlines=nlines, $
                                fieldtype=fieldtype, exzone=exzone, $
                                _ref_extra=_ref_extra
;
((*self.polines)[0])->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
nlines = self.nlines
fieldtype = self.fieldtype
exzone = self.exzone
;
end

;------------------------------------------------------------------------------

pro sunglobe_pfss::diffrot, target_date
;
;  Determine the number of days between the observation and the target date.
;
if target_date ne self.daterot then begin
    ndays = (anytim2tai(target_date) - utc2tai(self.date)) / 86400
;
;  Rotate the longitude values based on the latitude
;
    lat = 0.5*!pi - *self.pptth
    lon = *self.pptph + diff_rot(ndays, lat*!radeg, /carrington)*!dtor
    ptr = *self.pptr
;
;  Recalculate the cartesian coordinates.
;
    xp = ptr*cos(lat)*cos(lon)
    yp = ptr*cos(lat)*sin(lon)
    zp = *self.pzp
;
;  Store in the structure.
;
    ptr_free, self.pxp     &  self.pxp    = ptr_new(xp)
    ptr_free, self.pyp     &  self.pyp    = ptr_new(yp)
;
;  Step through the lines, and load in the new values.
;
    for i=0,self.npt-1 do begin
        ns = (*self.pnstep)[i]
        data = transpose([[xp[0:ns-1,i]], [yp[0:ns-1,i]], [zp[0:ns-1,i]]])
        ((*self.polines)[i])->setproperty, data=data
    endfor
endif
;
;  Store the rotation date.
;
self.daterot = target_date
;
end

;------------------------------------------------------------------------------

pro sunglobe_pfss::build
;
;  Load the PFSS common block.
;
@pfss_data_block
;
;  Find the nearest PFSS file, and load it into the common block.
;
target_date = (*self.psstate).target_date
pfssfile = pfss_time2file(target_date, /ssw_cat, /url)
pfss_restore, pfssfile
;
;  Build the field lines.
;
widget_control, /hourglass

bbox=[0.0, -90+self.exzone, 360, 90-self.exzone]
pfss_field_start_coord, self.fieldtype, self.nlines, bbox=bbox, radstart=1.02
pfss_trace_field
;
;  Get the number of lines, and the range of R values.
;
npt = n_elements(nstep)
rmin = min(rix, max=rmax)
;
;  Determine whether lines are open or closed.
;
open = intarr(npt)
for i=0,npt-1 do begin
    ns = nstep[i]
    if (max(ptr[0:ns-1,i])-rmin)/(rmax-rmin) gt 0.99 then begin
        irc  = get_interpolation_index(rix, ptr[0,i])
        ithc = get_interpolation_index(lat, 90-ptth[0,i]*!radeg)
        iphc = get_interpolation_index(lon, (ptph[0,i]*!radeg+360) mod 360)
        brc = interpolate(br, iphc, ithc, irc)
        if brc gt 0 then open[i] = 1 else open[i] = -1
    endif       ;  else open[i] = 0, which has already been done
endfor
;
;  Rotate the longitude values based on the latitude
;
ndays = (anytim2tai(target_date) - utc2tai(now)) / 86400
lat = 0.5*!pi - ptth
lon = ptph + diff_rot(ndays, lat*!radeg, /carrington)*!dtor
;
;  Convert to cartesian coordinates.
;
xp = ptr*cos(lat)*cos(lon)
yp = ptr*cos(lat)*sin(lon)
zp = ptr*sin(lat)
;
;  Store the data in the object structure.
;
self.date = now
self.daterot = target_date
ptr_free, self.pnstep  &  self.pnstep = ptr_new(nstep)
ptr_free, self.popen   &  self.popen  = ptr_new(open)
ptr_free, self.pptr    &  self.pptr   = ptr_new(ptr)
ptr_free, self.pptph   &  self.pptph  = ptr_new(ptph)
ptr_free, self.pptth   &  self.pptth  = ptr_new(ptth)
ptr_free, self.pxp     &  self.pxp    = ptr_new(xp)
ptr_free, self.pyp     &  self.pyp    = ptr_new(yp)
ptr_free, self.pzp     &  self.pzp    = ptr_new(zp)
;
;  Destroy any previously created field lines.
;
for i=0,self.npt-1 do obj_destroy, (*self.polines)[i]
ptr_free, self.polines
;
;  Create the field line graphics objects.
;
self.npt = npt
self.polines = ptr_new(objarr(npt))
for i=0,npt-1 do begin
    case open[i] of
       -1: color = [0b, 0b, 255b]
        0: color = [255b, 255b, 255b]
        1: color = [0b, 255b, 0b]
    endcase
    ns = nstep[i]
    ((*self.polines)[i]) = obj_new('idlgrpolyline', color=color, $
                                   xp[0:ns-1,i], yp[0:ns-1,i], zp[0:ns-1,i])
    self->add, ((*self.polines)[i])
endfor
(*self.psstate).hidepfss = 0
;
widget_control, hourglass=0
end

;------------------------------------------------------------------------------

pro sunglobe_pfss__define
struct = {sunglobe_pfss, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          nlines: 300, $
          exzone: 0.0, $
          fieldtype: 6, $
          date: '', $
          daterot: '', $
          npt: 0, $
          pnstep: ptr_new(), $
          popen: ptr_new(), $
          pptr: ptr_new(), $
          pptph: ptr_new(), $
          pptth: ptr_new(), $
          pxp: ptr_new(), $
          pyp: ptr_new(), $
          pzp: ptr_new(), $
          polines: ptr_new()}
end
