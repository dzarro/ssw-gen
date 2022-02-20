;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_EUI_FOV__DEFINE
;
; Purpose     :	Object graphics for EUI field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, EUI
;
; Explanation : Creates a field-of-view graphics object for the EUI instrument
;               high resolution channel for use within the SUNGLOBE program.
;               By default, the field-of-view is defined to be 1000x1000 arc
;               seconds.
;
; Syntax      :	To initially create:
;                       oEUI = OBJ_NEW('sunglobe_eui_fov', sstate=sstate)
;
;               To retrieve a property value:
;                       oEUI -> GetProperty, property=property
;
;               To set a property value:
;                       oEUI -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oEUI -> build
;
;               To destroy:
;                       OBJ_DESTROY, oEUI
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
;               XSIZE   = Size in arcsec in X direction.  (Default=1000)
;
;               YSIZE   = Size in arcsec in Y direction.  (Default=1000)
;
;               XCEN    = Center in arcsec in X direction.  (Default=0)
;
;               YCEN    = Center in arcsec in Y direction.  (Default=0)
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Calls       :	SUNGLOBE_EUI_FOV::BUILD
;
; History     :	Version 1, 19-Jan-2016, William Thompson, GSFC
;               Version 2, 05-Feb-2016, WTT, GetProperty bug fix
;               Version 3, 10-Apr-2019, WTT, fix pointer free bug
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_eui_fov::init, sstate=sstate, xsize=xsize, ysize=ysize, $
                                 xcen=xcen, ycen=ycen, _extra=_extra
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
self.xsize = 1000.0             ;Width in X
self.ysize = 1000.0             ;Width in Y
self.xcen = 0.0                 ;Center in X
self.ycen = 0.0                 ;Center in Y

if n_elements(xsize) eq 1 then self.xsize = xsize
if n_elements(ysize) eq 1 then self.ysize = ysize
if n_elements(xcen) eq 1 then self.xcen = xcen
if n_elements(ycen) eq 1 then self.ycen = ycen
;
;  Create polyline descriptions for the box.
;
xbox = [-1., 1., 1., -1., -1.]
ybox = [-1., -1., 1., 1., -1.]
zbox = [1., 1., 1., 1., 1.]
self.obox = obj_new('idlgrpolyline', color=[255,255,255], xbox, ybox, zbox, $
                 _extra=_extra)
;
self->add, self.obox
;
;  Build the field-of-view graphics based on the input properties.
;
self->build
return, 1
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_fov::setproperty, sstate=sstate, xsize=xsize, ysize=ysize, $
                                   xcen=xcen, ycen=ycen, _extra=_extra
;
self->idlgrmodel::setproperty, _extra=_extra
self.obox->setproperty, _extra=_extra
;
if datatype(sstate) eq 'STC' then begin
    ptr_free, self.psstate
    self.psstate = ptr_new(sstate)
endif
if n_elements(xsize) eq 1 then self.xsize = xsize
if n_elements(ysize) eq 1 then self.ysize = ysize
if n_elements(xcen) eq 1 then self.xcen = xcen
if n_elements(ycen) eq 1 then self.ycen = ycen
;
;  Build the field-of-view graphics based on the input properties.
;
self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_fov::getproperty, sstate=sstate, xsize=xsize, ysize=ysize, $
                                   xcen=xcen, ycen=ycen, _ref_extra=_ref_extra
;
self.obox->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
xsize = self.xsize
ysize = self.ysize
xcen = self.xcen
ycen = self.ycen
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_fov::build
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
dtor = !dpi / 180.d0
asectorad = dtor / 3600.d0
;
xbox = [-0.5, 0.5, 0.5, -0.5, -0.5]
ybox = [-0.5, -0.5, 0.5, 0.5, -0.5]
;
;  Define the pointing box, and convert to arcseconds.
;
xbox = asectorad * (xbox*self.xsize + self.xcen + xsc)
ybox = asectorad * (ybox*self.ysize + self.ycen + ysc)
;
;  Convert to cartesian coordinates
;
data = dblarr(3,5)
data[0,*] = dist * tan(xbox)
data[1,*] = dist * tan(ybox) / cos(xbox)
data[2,*] = 1
self.obox->setproperty, data=data
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_fov__define
struct = {sunglobe_eui_fov, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          xsize: 0, $
          ysize: 1, $
          xcen: 0.0, $
          ycen: 0.0, $
          obox: obj_new()}
end
