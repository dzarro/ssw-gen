;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_MAKE_OBJECTS()
;
; Purpose     :	Creates the object hierarchy for SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Creates the graphic objects used by the SUNGLOBE program.
;
; Syntax      :	oResult = SUNGLOBE_MAKE_OBJECTS(DRAWSIZE, OWINDOW)
;
; Examples    :	Called from sunglobe.pro
;
; Inputs      :	DRAWSIZE = Size of the drawing window
;               OWINDOW  = Object ID of graphics window
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is a structure containing all the
;               object IDs.
;
; Opt. Outputs:	None
;
; Keywords    :	Keywords to TRACKBALL, SUNORB__DEFINE, and SUNGLOBE_MAKE_GRID
;               are passed through.
;
; Calls       :	SUNGLOBE_MAKE_GRID, WCS_AU, WCS_RSUN
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	Based on d_globe.pro in the IDL examples directory.
;
; History     :	Version 1, 19-Jan-2016, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_make_objects, drawsize, oWindow, _extra=_extra
;
;  Create the view object.
;
origview = [-1.1, -1.1, 2.2, 2.2]
origeye = wcs_au() / wcs_rsun()
oView = obj_new('idlgrview', projection=2, eye=origeye, color=[0,0,0], $
                viewplane_rect=origview, zclip=[3, -3])
;
;  Create model objects for translation and rotation.
;
omodeltranslate=obj_new('idlgrmodel')
omodelrotate=obj_new('idlgrmodel')
omodeltranslate->add, omodelrotate
oview->add, omodeltranslate
;
;  Create and display the PLEASE WAIT text.
;
textlocation = [origview[0]+0.5*origview[2], origview[1]+0.5*origview[3]]
ofont = obj_new('idlgrfont', 'Helvetica', size=20)
otext = obj_new('idlgrtext', 'Starting up  Please wait...', align=0.5, $
        location=textlocation, color=[255,255,0], font=ofont)
omodelrotate->add, otext
owindow->draw, oview
;    
;  Create the trackball object.
;
otrack = obj_new('trackball', [drawsize[0]/2.0, drawsize[0]/2.0], $
                 drawsize[0], _extra=_extra)
;
;  Create the pixmap window for manipulating the image, and create the image
;  object.
;
opixmap = obj_new('idlgrbuffer', units=0, dimensions=[2880,1440])
opixview = obj_new('idlgrview', color=[0,0,0])
opixmodel = obj_new('idlgrmodel')
opixview->add, opixmodel
opixmap->draw, opixview
oimage = opixmap->read()
;
;  Do the same for a lower resolution version for rapid manipulation.
;
opixmap_small = obj_new('idlgrbuffer', units=0, dimensions=[720,360])
opixview_small = obj_new('idlgrview', color=[0,0,0])
opixmodel_small = obj_new('idlgrmodel')
opixview_small->add, opixmodel_small
opixmap_small->draw, opixview_small
;
;  Create the sunorb object and add it to the model hierarchy.
;
osphere = obj_new('sunorb', /tex_coords, texture_map=oimage, $
                  color=[255,255,255], radius=1.0, _extra=_extra)
omodelrotate->add, osphere
ogrid = sunglobe_make_grid(font=ofont, _extra=_extra)
omodelrotate->add, ogrid
;
;  Initialize the model attitude to put North up and 0 longitude at the center.
;
omodelrotate->rotate, [1, 0, 0], -90
omodelrotate->rotate, [0, 1, 0], -90
;
;  Define this as the beginning state.
;
omodeltranslate->getproperty, transform=origtranslate
omodelrotate->getproperty, transform=origrotate
;
;  Make a boresight symbol for the spacecraft pointing, and add it to the
;  translate model.
;
opolysymbol = obj_new('idlgrsymbol', data=2, size=0.02)
obore = obj_new('idlgrpolyline', symbol=opolysymbol, data=[0,0,1.1], $
                color=[255,255,255], /hide)
omodeltranslate->add, obore
;
;  Make a container object which contains the other main graphics objects, to
;  make cleanup easier.
;
ocontainer = obj_new('idl_container')
ocontainer->add, oview
ocontainer->add, ofont
ocontainer->add, otext
ocontainer->add, otrack
ocontainer->add, opixmap
ocontainer->add, opixmap_small
ocontainer->add, opixview
ocontainer->add, opixview_small
ocontainer->add, oimage
ocontainer->add, opolysymbol
ocontainer->add, obore
;
;  Return the structure containing the various model IDs needed by the other
;  programs.
;
return, {oview:oview, $
         omodeltranslate: omodeltranslate, $
         omodelrotate: omodelrotate, $
         osphere: osphere, $
         ogrid: ogrid, $
         otrack: otrack, $
         owindow: owindow, $
         ocontainer: ocontainer, $
         otext: otext, $
         ofont: ofont, $
         opixmap: opixmap, $
         opixmap_small: opixmap_small, $
         opixmodel: opixmodel, $
         opixmodel_small: opixmodel_small, $
         opixview: opixview, $
         opixview_small: opixview_small, $
         oimage: oimage, $
         obore: obore, $
         origtranslate: origtranslate, $
         origrotate: origrotate, $
         origview: origview, $
         origeye: origeye}
;
end
