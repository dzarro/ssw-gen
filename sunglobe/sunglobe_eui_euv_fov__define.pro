;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_EUI_EUV_FOV__DEFINE
;
; Purpose     :	Object graphics for EUI/HRI/EUV field-of-view in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning, EUI
;
; Explanation : Creates a field-of-view graphics object for the EUI instrument
;               high resolution EUV channel for use within the SUNGLOBE program.
;               By default, the field-of-view is defined to be 1000x1000 arc
;               seconds.
;
; Syntax      :	To initially create:
;                       oEUIEUV = OBJ_NEW('sunglobe_eui_euv_fov', sstate=sstate)
;
;               To retrieve a property value:
;                       oEUIEUV -> GetProperty, property=property
;
;               To set a property value:
;                       oEUIEUV -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oEUIEUV -> build
;
;               To destroy:
;                       OBJ_DESTROY, oEUIEUV
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
; Calls       :	SUNGLOBE_EUI_EUV_FOV::BUILD
;
; History     :	Version 1, 19-Jan-2016, William Thompson, GSFC
;               Version 2, 05-Feb-2016, WTT, GetProperty bug fix
;               Version 3, 10-Apr-2019, WTT, fix pointer free bug
;               Version 4, 10-Nov-2021, WTT, include nominal offsets to S/C
;               Version 5, 24-Feb-2022, WTT, split EUI into EUV and LYA channels
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_eui_euv_fov::init, sstate=sstate, xsize=xsize, ysize=ysize, $
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
;
;  Get the offset from the boresight.
;
sunglobe_get_ins_offset, sstate, 'EUI/HRI/EUV', xoffset, yoffset
self.xoffset = xoffset
self.yoffset = yoffset
;
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

pro sunglobe_eui_euv_fov::setproperty, sstate=sstate, xsize=xsize, ysize=ysize, $
                                   xoffset=xoffset, yoffset=yoffset, $
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
if n_elements(xoffset) eq 1 then self.xoffset = xoffset
if n_elements(yoffset) eq 1 then self.yoffset = yoffset
;
;  Build the field-of-view graphics based on the input properties.
;
self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_euv_fov::getproperty, sstate=sstate, xsize=xsize, ysize=ysize, $
                                   xoffset=xoffset, yoffset=yoffset, $
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
xoffset = self.xoffset
yoffset = self.yoffset
;
end

;------------------------------------------------------------------------------

pro sunglobe_eui_euv_fov::build
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

pro sunglobe_eui_euv_fov__define
struct = {sunglobe_eui_euv_fov, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          xsize: 0, $
          ysize: 1, $
          xcen: 0.0, $
          ycen: 0.0, $
          xoffset: 0.0, $
          yoffset: 0.0, $
          obox: obj_new()}
end
