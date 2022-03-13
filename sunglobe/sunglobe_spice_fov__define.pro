;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_SPICE_FOV__DEFINE
;
; Purpose     :	Object graphics for SPICE field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, SPICE
;
; Explanation :	Creates a field-of-view graphics object for the SPICE
;               instrument for use within the SUNGLOBE program.  The
;               field-of-view is constructed based on the selected slit, the
;               number of raster positions, the raster step size between
;               positions, and any horizontal offset from the center position.
;               For the narrow slits, the graphic includes the 30x30 arcsecond
;               co-alignment boxes at the top and bottom.  The displayed
;               graphic depends on the perspective (eye distance).
;
; Syntax      :	To initially create:
;                       oSPICE = OBJ_NEW('sunglobe_spice_fov', sstate=sstate)
;
;               To retrieve a property value:
;                       oSPICE -> GetProperty, property=property
;
;               To set a property value:
;                       oSPICE -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oSPICE -> build
;
;               To destroy:
;                       OBJ_DESTROY, oSPICE
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
;               SLITNUM = Slit number, 0, 1, 2, or 3.  (Default=0)
;
;               NSTEPS  = Number of raster steps.  (Default=1)
;
;               STEPSIZE= Horizontal step size in arcseconds.  (Default=0)
;
;               MIDPOS  = Horizontal offset of raster center in arcseconds.
;                         (Default=0)
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Calls       :	SUNGLOBE_SPICE_FOV::BUILD
;
; History     :	Version 1, 12-Jan-2016, William Thompson, GSFC
;               Version 2, 05-Feb-2016, WTT, GetProperty bug fix
;               Version 3, 10-Apr-2019, WTT, fix pointer free bug
;               Version 4, 10-Nov-2021, WTT, include nominal offsets to S/C
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_spice_fov::init, sstate=sstate, slitnum=slitnum, $
                                   nsteps=nsteps, stepsize=stepsize, $
                                   midpos=midpos, _extra=_extra
;
;  Can't initialize the object without an sstate array.
;
if datatype(sstate) ne 'STC' then begin
    print, 'SSTATE is not a structure'
    return, 0
endif
;
;  Initialize the graphics model containing the field-of-view description.
;
if (self->idlgrmodel::init(_extra=_extra) ne 1) then begin
    print, 'Unable to initiate structure'
    return, 0
endif
;
;  Store the input parameters into the object.
;
self.psstate = ptr_new(sstate)  ;Widget state structure
self.slitnum = 0                ;Slit number 0-3
self.nsteps = 1                 ;Number of step positions
self.stepsize = 0.0             ;Distance in arcsec between steps
self.midpos = 0.0               ;Relative middle of raster in arcsec
;
;  Get the offset from the boresight.
;
sunglobe_get_ins_offset, sstate, 'SPICE', xoffset, yoffset
self.xoffset = xoffset
self.yoffset = yoffset
;
if n_elements(slitnum) eq 1 then self.slitnum = slitnum
if n_elements(nsteps) eq 1 then self.nsteps = nsteps
if n_elements(stepsize) eq 1 then self.stepsize = stepsize
if n_elements(midpos) eq 1 then self.midpos = midpos
;
;  Create polyline descriptions for the slit section, and for the north and
;  south imaging sections.
;
xbox = [-1., 1., 1., -1., -1.]
ybox = [-1., -1., 1., 1., -1.]
zbox = [1., 1., 1., 1., 1.]
self.onorth = obj_new('idlgrpolyline', color=[255,255,255], xbox, ybox, zbox, $
                 /hide, _extra=_extra)
self.oslit  = obj_new('idlgrpolyline', color=[255,255,255], xbox, ybox, zbox, $
                 /hide)
self.osouth = obj_new('idlgrpolyline', color=[255,255,255], xbox, ybox, zbox, $
                 /hide)
;
self->add, self.onorth
self->add, self.oslit
self->add, self.osouth
;
;  Build the field-of-view graphics based on the input properties.
;
self->build
return, 1
;
end

;------------------------------------------------------------------------------

pro sunglobe_spice_fov::setproperty, sstate=sstate, slitnum=slitnum, $
                                     nsteps=nsteps, stepsize=stepsize, $
                                     xoffset=xoffset, yoffset=yoffset, $
                                     midpos=midpos, _extra=_extra
;
self->idlgrmodel::setproperty, _extra=_extra
self.onorth->setproperty, _extra=_extra
self.oslit->setproperty, _extra=_extra
self.osouth->setproperty, _extra=_extra
;
if datatype(sstate) eq 'STC' then begin
    ptr_free, self.psstate
    self.psstate = ptr_new(sstate)
endif
if n_elements(slitnum) eq 1 then self.slitnum = slitnum
if n_elements(nsteps) eq 1 then self.nsteps = nsteps
if n_elements(stepsize) eq 1 then self.stepsize = stepsize
if n_elements(midpos) eq 1 then self.midpos = midpos
if n_elements(xoffset) eq 1 then self.xoffset = xoffset
if n_elements(yoffset) eq 1 then self.yoffset = yoffset
;
;  Build the field-of-view graphics based on the input properties.
;
self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_spice_fov::getproperty, sstate=sstate, slitnum=slitnum, $
                                     nsteps=nsteps, stepsize=stepsize, $
                                     xoffset=xoffset, yoffset=yoffset, $
                                     midpos=midpos, _ref_extra=_ref_extra
;
self.onorth->getproperty, _extra=_ref_extra
self.osouth->getproperty, _extra=_ref_extra
self.oslit->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
slitnum = self.slitnum
nsteps = self.nsteps
stepsize = self.stepsize
midpos = self.midpos
xoffset = self.xoffset
yoffset = self.yoffset
;
end

;------------------------------------------------------------------------------

pro sunglobe_spice_fov::build
;
;  Get the solar distance, and subtract one solar radius to stay in front of
;  the Sun.
;
(*self.psstate).oview->getproperty, eye=eye
dist = eye - 1
;
;  Get the boresight position from the widget.
;
widget_control, (*self.psstate).wxsc, get_value=xsc
widget_control, (*self.psstate).wysc, get_value=ysc
xsc = xsc + self.xoffset
ysc = ysc + self.yoffset
dtor = !dpi / 180.d0
asectorad = dtor / 3600.d0
;
xbox = [-1., 1., 1., -1., -1.]
ybox = [-1., -1., 1., 1., -1.]
zbox = [1., 1., 1., 1., 1.]
;
;  Define the north pointing box, and convert to arcseconds.
;
nhalfwidth = (((self.nsteps-1)>0)*abs(self.stepsize) + 30) / 2
xnorth = asectorad * (xbox * nhalfwidth + self.midpos + xsc)
ynorth = asectorad * (ybox * 15 + ysc + 390)
;
;  Convert to cartesian coordinates
;
data = dblarr(3,5)
data[0,*] = dist * tan(xnorth)
data[1,*] = dist * tan(ynorth) / cos(xnorth)
data[2,*] = 1
self.onorth->setproperty, data=data, hide=(self.slitnum eq 3)
;
;  Do the same for the slit pointing box.
;
halfheight = 5.5
case self.slitnum of
    1: width = 4.0
    2: width = 6.0
    3: begin
        width = 30.0
        halfheight = 7.0
    end
    else: width = 2.0           ;Slit #0 is the default
endcase
halfheight = halfheight * 60
halfwidth = (((self.nsteps-1)>0)*abs(self.stepsize) + width) / 2
xslit = asectorad * (xbox * halfwidth + self.midpos + xsc)
yslit = asectorad * (ybox * halfheight + ysc)
data[0,*] = dist * tan(xslit)
data[1,*] = dist * tan(yslit) / cos(xslit)
self.oslit->setproperty, data=data, hide=0
;
;  Do the same for the south pointing box.
;
xsouth = asectorad * (xbox * nhalfwidth + self.midpos + xsc)
ysouth = asectorad * (ybox * 15 + ysc - 390)
data[0,*] = dist * tan(xsouth)
data[1,*] = dist * tan(ysouth) / cos(xsouth)
self.osouth->setproperty, data=data, hide=(self.slitnum eq 3)
;
end

;------------------------------------------------------------------------------

pro sunglobe_spice_fov__define
struct = {sunglobe_spice_fov, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          slitnum: 0, $
          nsteps: 1, $
          stepsize: 0.0, $
          midpos: 0.0, $
          xoffset: 0.0, $
          yoffset: 0.0, $
          onorth: obj_new(), $
          oslit: obj_new(), $
          osouth: obj_new()}
end
