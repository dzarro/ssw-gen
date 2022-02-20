;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_ORBIT__DEFINE
;
; Purpose     :	Object graphics for orbit trace in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, Orbit
;
; Explanation : Creates a graphics object showing the subspacecraft point on
;               the solar surface for several time steps.  Steps in the past
;               are shown as crosses (X), and points in the future are shown as
;               diamonds.  Both symbols on top of each other mark the target
;               time.
;
; Syntax      :	To initially create:
;                       oOrbit = OBJ_NEW('sunglobe_orbit', sstate=sstate)
;
;               To retrieve a property value:
;                       oOrbit -> GetProperty, property=property
;
;               To set a property value:
;                       oOrbit -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oOrbit -> build
;
;               To destroy:
;                       OBJ_DESTROY, oOrbit
;
; Examples    :	See sunglobe.pro, sunglobe_event.pro
;
; Keywords    :	The following keyword is required when initializing the object.
;
;               SSTATE  = Widget top-level state structure
;
;               The following keywords pertain to the INIT, GETPROPERTY, and
;               SETPROPERTY methods.
;
;               NTIMES   = Number of time steps both before and after the target
;                          time.  The total number of points plotted is
;                          2*NTIMES+1.
;
;               TIMESTEP = The time difference between symbols.
;
;               TIMETYPE = The time units: 'Days', 'Hours', or 'Minutes'
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Calls       :	SUNGLOBE_ORBIT::BUILD
;
; History     :	Version 1, 02-Sep-2016, William Thompson, GSFC
;               Version 2, 14-Nov-2016, WTT, fix bug when POBEFOREMODEL not defined
;               Version 3, 10-Apr-2019, WTT, fix pointer free bug
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_orbit::init, sstate=sstate, ntimes=ntimes, $
                               timestep=timestep, timetype=timetype, $
                               _extra=_extra
;
;  Can't initialize the object without an sstate array.
;
if datatype(sstate) ne 'STC' then begin
    print, 'SSTATE is not a structure'
    return, 0
endif
;
;  Initialize the graphics model containing the orbit description.
;
if (self->idlgrmodel::init(_extra=_extra) ne 1) then begin
    print, 'Unable to initiate structure'
    return, 0
endif
;
;  Store the input parameters into the object.
;
self.psstate = ptr_new(sstate)  ;Widget state structure
self.ntimes = 5                 ;Number of before/after steps
self.timestep = 1.0d0           ;Size of steps
self.timetype = 'Days'          ;Type of step

if n_elements(ntimes)   eq 1 then self.ntimes = ntimes
if n_elements(timestep) eq 1 then self.timestep = timestep
if n_elements(timetype) eq 1 then self.timetype = timetype
;
;  Build the orbit graphics based on the input properties.
;
self->build
;
return, 1
end

;------------------------------------------------------------------------------

pro sunglobe_orbit::setproperty, sstate=sstate, ntimes=ntimes, $
                                 timestep=timestep, timetype=timetype, $
                                 _extra=_extra
;
self->idlgrmodel::setproperty, _extra=_extra
;
rebuild = 0
if datatype(sstate) eq 'STC' then begin
    ptr_free, self.psstate
    self.psstate = ptr_new(sstate)
    rebuild = 1
endif
if n_elements(ntimes) eq 1 then begin
    self.ntimes = ntimes
    rebuild = 1
endif
if n_elements(timestep) eq 1 then begin
    self.timestep = timestep
    rebuild = 1
endif
if n_elements(timetype) eq 1 then begin
    self.timetype = timetype
    rebuild = 1
endif
;
;  Build the orbit graphics based on the input properties.
;
if rebuild then self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_orbit::getproperty, sstate=sstate, ntimes=ntimes, $
                                 timestep=timestep, timetype=timetype, $
                                 _ref_extra=_ref_extra
;
if ptr_valid(self.pobeforemodel) then $
  ((*self.pobeforemodel)[0])->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
ntimes = self.ntimes
timestep = self.timestep
timetype = self.timetype
;
end

;------------------------------------------------------------------------------

pro sunglobe_orbit::build
;
;  Check to see whether the data points need to be recalculated.
;
target_date = (*self.psstate).target_date
npts = 2*self.ntimes + 1
case self.timetype of
    'Days': nseconds = 86400.d0 * self.timestep
    'Hours': nseconds = 3600.d0 * self.timestep
    'Minutes': nseconds = 60.d0 * self.timestep
    else: nseconds = self.timestep
endcase
;
self.date = target_date
self.npts = npts
self.nseconds = nseconds
;
;  Take the test offset into account if applicable.
;
utc0 = anytim2utc(target_date, /external)
test_offset = (*self.psstate).test_offset
if test_offset ne 0 then utc0.year = utc0.year + round(test_offset)
tai = utc2tai(utc0) + nseconds * (indgen(npts) - self.ntimes)
utc = tai2utc(tai)
errmsg = ''
lonlat = get_sunspice_lonlat(utc, (*self.psstate).spacecraft, $
                             system='Carrington', /degrees, errmsg=errmsg)
if errmsg eq '' then begin
    narray = self.ntimes + 1
    self.pobeforepoly = ptr_new(objarr(narray))
    self.poafterpoly  = ptr_new(objarr(narray))
    self.pobeforemodel = ptr_new(objarr(narray))
    self.poaftermodel  = ptr_new(objarr(narray))
    obeforesymbol = obj_new('idlgrsymbol', data=7, size=0.01)
    oaftersymbol = obj_new('idlgrsymbol', data=4, size=0.01)
    xx = [0.0, 0.0]
    yy = [0.0, 0.0]
    zz = [1.0, 1.0]
    dtor = !dpi / 180.d0
    for i=0,narray-1 do begin
        (*self.pobeforepoly)[i] = obj_new('idlgrpolyline', xx, yy, zz, $
                                          color=[255,255,255], $
                                          symbol=obeforesymbol, $
                                          linestyle=6)
        (*self.pobeforemodel)[i] = obj_new('idlgrmodel')
        (*self.pobeforemodel)[i]->add, (*self.pobeforepoly)[i]
        (*self.pobeforemodel)[i]->rotate, [0,1,0], 90.0
        (*self.pobeforemodel)[i]->rotate, [0,0,1], lonlat[1,i]
        phi = lonlat[1,i] * dtor
        vector = [-sin(phi), cos(phi), 0]
        (*self.pobeforemodel)[i]->rotate, vector, -lonlat[2,i]
        self->add, (*self.pobeforemodel)[i]
;
        (*self.poafterpoly)[i] = obj_new('idlgrpolyline', xx, yy, zz, $
                                         color=[255,255,255], $
                                         symbol=oaftersymbol, linestyle=6)
        (*self.poaftermodel)[i] = obj_new('idlgrmodel')
        (*self.poaftermodel)[i]->add, (*self.poafterpoly)[i]
        (*self.poaftermodel)[i]->rotate, [0,1,0], 90.0
        (*self.poaftermodel)[i]->rotate, [0,0,1], lonlat[1,i+narray-1]
        phi = lonlat[1,i+narray-1] * dtor
        vector = [-sin(phi), cos(phi), 0]
        (*self.poaftermodel)[i]->rotate, vector, -lonlat[2,i+narray-1]
        self->add, (*self.poaftermodel)[i]
    endfor
endif
;
end

;------------------------------------------------------------------------------

pro sunglobe_orbit__define
struct = {sunglobe_orbit, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          ntimes: 0, $
          npts: 0, $
          timestep: 0.0d0, $
          timetype: 'Days', $
          date: '', $
          nseconds: 0.0d0, $
          pobeforepoly: ptr_new(), $
          poafterpoly: ptr_new(), $
          pobeforemodel: ptr_new(), $
          poaftermodel: ptr_new()}
end
