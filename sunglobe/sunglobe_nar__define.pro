;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_NAR__DEFINE
;
; Purpose     :	Object graphics for active region IDs in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, Orbit
;
; Explanation : Creates a graphics object showing the NOAA active region ID
;               numbers.
;
; Syntax      :	To initially create:
;                       oNar = OBJ_NEW('sunglobe_nar', sstate=sstate)
;
;               To retrieve a property value:
;                       oNar -> GetProperty, property=property
;
;               To set a property value:
;                       oNar -> SetProperty, property=property
;
;               To build the ID graphic:
;                       oNar -> build
;
;               To destroy:
;                       OBJ_DESTROY, oNar
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
;               TARGET_DATE = Target date used by SUNSPICE_GET_NAR
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Calls       :	SUNGLOBE_NAR::BUILD
;
; History     :	Version 1, 01-Apr-2019, William Thompson, GSFC
;               Version 2, 02-Apr-2019, WTT, use orange for labels
;               Version 3, 10-Apr-2019, WTT, fix pointer free bug
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_nar::init, sstate=sstate, target_date=target_date, $
                               _extra=_extra
;
;  Can't initialize the object without an sstate array.
;
if datatype(sstate) ne 'STC' then begin
    print, 'SSTATE is not a structure'
    return, 0
endif
;
;  Initialize the graphics model containing the ID description.
;
if (self->idlgrmodel::init(_extra=_extra) ne 1) then begin
    print, 'Unable to initiate structure'
    return, 0
endif
;
;  Store the input parameters into the object.
;
self.psstate = ptr_new(sstate)  ;Widget state structure
self.target_date = sstate.target_date
if n_elements(target_date) eq 1 then self.target_date = target_date
;
;  Build the ID graphics based on the input properties.
;
self->build
;
return, 1
end

;------------------------------------------------------------------------------

pro sunglobe_nar::setproperty, sstate=sstate, target_date=target_date, $
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
;
;  If the target date has been modified, then rebuild the graphic.
;
if n_elements(target_date) eq 1 then begin
    if self.target_date ne target_date then rebuild = 1
    self.target_date = target_date
endif
;
;  Build the ID graphics based on the input properties.
;
if rebuild then self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_nar::getproperty, sstate=sstate, target_date=target_date, $
                               _ref_extra=_ref_extra
;
if ptr_valid(self.ponarmodel) then $
  ((*self.ponarmodel)[0])->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
target_date = self.target_date
;
end

;------------------------------------------------------------------------------

pro sunglobe_nar::build
;
;  First, destroy any IDs that were previously defined.
;
for i=0,self.n_nar-1 do obj_destroy, (*self.ponarmodel)[i]
;
;  Get the NOAA active region IDs and locations, and initialize the graphics
;  objects.
;
sunglobe_get_nar, self.target_date, noaa, lon, lat
self.n_nar = n_elements(noaa)
if self.n_nar eq 0 then self.ponarmodel = ptr_new() else $
  self.ponarmodel = ptr_new(objarr(self.n_nar))
;
;  Define the parameters used to define the characters.
;
color = [255,127,0]
char_dimensions = [0.05, 0.05]
dtor = !dpi / 180.d0
;
;  Step through the NOAA IDs, and calculate the label location, as well as the
;  orientation.  Apply a tiny fudge factor to make sure that the label clears
;  the globe.
;
for i=0,self.n_nar-1 do begin
    phi   = dtor * lon[i]
    theta = dtor * lat[i]
    location = [cos(phi)*cos(theta), sin(phi)*cos(theta), sin(theta)]*1.001
    updir = [-cos(phi)*sin(theta), -sin(phi)*sin(theta), cos(theta)]
    baseline = [-sin(phi), cos(phi)]
    (*self.ponarmodel)[i] = obj_new('IDLgrText', '1'+ntrim(noaa[i]), $
                                    location=location, updir=updir, $
                                    baseline=baseline, color=color, $
                                    char_dimensions=char_dimensions, $
                                    alignment=0.5, vertical_alignment=0.5)
    self->add, (*self.ponarmodel)[i]
endfor
;
end

;------------------------------------------------------------------------------

pro sunglobe_nar__define
struct = {sunglobe_nar, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          target_date: '', $
          n_nar: 0, $
          ponarmodel: ptr_new()}
end
