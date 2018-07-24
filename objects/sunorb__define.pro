;+
; Project     :	ORBITER - SPICE
;
; Name        :	SunOrb
;
; Purpose     :	Sphere object graphic for solar images
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Creates a polyhedron framework approximating a sphere for
;               object graphics that solar heliographic maps can be displayed
;               on.  Based on orb__define.pro in the IDL examples tree.
;
; Syntax      :	To initially create:
;                       oSunOrb = OBJ_NEW('SunOrb')
;
;               To retrieve a property value:
;                       oSunOrb -> GetProperty
;
;               To set a property value:
;                       oSunOrb -> SetProperty
;
;               To destroy:
;                       OBJ_DESTROY, oSunOrb
;
; Examples    :	Create a SunOrb centered at the origin with a radius of 0.5:
;
;		oSunOrb = OBJ_NEW('SunOrb', POSITION=[0,0,0], RADIUS=0.5) 
;
; Keywords    :	The following keywords pertain to the INIT, GETPROPERTY, and
;               SETPROPERTY methods.  
;
;               POSITION:  A three-element vector, [x,y,z], specifying the
;                       position of the center of the orb, measured in data
;                       units.  Defaults to [0,0,0].
;
;               RADIUS: A floating point number representing the radius of the
;                       orb (measured in data units).  The default is 1.0.
;
;               ORBSIZE:  A floating point number representing the distance in
;                       degrees between grid points.  The default is 5.
;
;               The following keyword pertains only to the INIT method:
;
;               TEX_COORDS:  Set this keyword to a nonzero value if texture map
;                       coordinates are to be generated for the sunorb.
;
;               The following keyword pertains only to the GETPROPERTY method:
;
;               POBJ: Returns the polygon object.
;
;               Note that keywords accepted by the corresponding methods for
;               IDLgrModel and/or IDLgrPolygon are also accepted here.
;
; Calls       :	SUNORB::BUILDPOLY
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	orb__define.pro written by RF, September 1996.
;
; History     :	Version 1, 20-Oct-2015, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
;----------------------------------------------------------------------------
; SUNORB::INIT
;
; Purpose:
;  Initializes a SunOrb object.
;
;  This function returns a 1 if initialization is successful, or 0 otherwise.
;
FUNCTION SunOrb::Init, POSITION=position, RADIUS=radius, ORBSIZE=orbsize, $
                       TEX_COORDS=tex_coords, _extra=_extra

    IF (self->IDLgrModel::Init(_extra=_extra) NE 1) THEN RETURN, 0

    self.position = [0.0,0.0,0.0]
    self.radius = 1.0
    self.orbsize = 5.0

    IF (N_ELEMENTS(position) EQ 3) THEN $
        self.position = position

    IF (N_ELEMENTS(radius) EQ 1) THEN $
        self.radius = radius

    IF (N_ELEMENTS(orbsize) EQ 1) THEN $
        self.orbsize = orbsize

    IF (N_ELEMENTS(tex_coords) EQ 1) THEN $
        self.texture = tex_coords

    ; Initialize the polygon object that will be used to represent
    ; the sunorb.
    self.oPoly = OBJ_NEW('IDLgrPolygon', SHADING=1, /REJECT, _extra=_extra)

    self->Add,self.oPoly

    ; Build the polygon vertices and connectivity based on property settings.
    self->BuildPoly

    RETURN, 1
END

;----------------------------------------------------------------------------
; SUNORB::CLEANUP
;
; Purpose:
;  Cleans up all memory associated with the sunorb.
;
PRO SunOrb::Cleanup

    ; Cleanup the polygon object used to represent the sunorb.
    OBJ_DESTROY, self.oPoly

    ; Cleanup the superclass.
    self->IDLgrModel::Cleanup
END

;----------------------------------------------------------------------------
; SUNORB::SETPROPERTY
;
; Purpose:
;  Sets the value of properties associated with the sunorb object.
;
PRO SunOrb::SetProperty, $
    ORBSIZE=orbsize, $
    PARENT=parent, $ ; Pass along to IDLgrModel only.
    POSITION=position, $
    RADIUS=radius, $
    _extra=_extra

    ; Pass along extraneous keywords to the superclass and/or to the
    ; polygon used to represent the sunorb.
    self->IDLgrModel::SetProperty, _extra=_extra
    self.oPoly->SetProperty, _extra=_extra

    IF (N_ELEMENTS(position) EQ 3) THEN $
        self.position = position

    IF (N_ELEMENTS(radius) EQ 1) THEN $
        self.radius = radius

    IF (N_ELEMENTS(orbsize) EQ 1) THEN $
        self.orbsize = orbsize

    ; Rebuild the polygon according to keyword settings.
    self->BuildPoly
END

;----------------------------------------------------------------------------
; SUNORB::GETPROPERTY
;
; Purpose:
;  Retrieves the value of properties associated with the sunorb object.
;
PRO SunOrb::GetProperty, POSITION=position, RADIUS=radius, ORBSIZE=orbsize,$
                         POBJ=pobj, _ref_extra=_ref_extra

    ; Retrieve extra properties from polygon first, then model
    ; so that the model settings (for common keywords) will prevail.
    self.oPoly->GetProperty, _EXTRA=_REF_EXTRA
    self->IDLgrModel::GetProperty, _EXTRA=_REF_EXTRA

    position = self.position
    radius = self.radius 
    orbsize = self.orbsize 
    pobj = self.oPoly
END

;----------------------------------------------------------------------------
; SUNORB::BUILDPOLY
;
; Purpose:
;  Sets the vertex and connectivity arrays for the polygon used to
;  represent the sunorb.
;
PRO SunOrb::BuildPoly
    ; Build the sunorb.

    ; Number of rows and columns of vertices is based upon the orbsize
    ; property.
    nrows = (round(180. / self.orbsize) - 1) > 2
    ncols = (round(360. / self.orbsize) + 1) > 4

    ; Create the vertex list and the connectivity array.
    nverts = nrows*ncols + 2
    nconn = (ncols*(nrows-1)*5) + (2*ncols*4)
    conn = LONARR(ncols*(nrows-1)*5 + 2*ncols*4)
    verts = FLTARR(3, nverts)
    IF (self.texture NE 0) THEN $
        tex = FLTARR(2,nverts)

    ; Fill in the vertices.
    i = 0L
    j = 0L
    k = 0L
    tzinc = (!PI)/FLOAT(nrows+1)
    tz = (!PI/2.0) - tzinc 
    FOR k=0,(nrows-1) DO BEGIN
        z = SIN(tz)*self.radius
        r = COS(tz)*self.radius
        t = 0
        IF (self.texture NE 0) THEN BEGIN
            tinc = (2.*!PI)/FLOAT(ncols-1)
        ENDIF ELSE BEGIN
            tinc = (2.*!PI)/FLOAT(ncols)
        ENDELSE
        FOR j=0,(ncols-1) DO BEGIN
            verts[0,i] = r*COS(t) + self.position[0]
            verts[1,i] = r*SIN(t) + self.position[1]
            verts[2,i] = z + self.position[2]

            IF (self.texture NE 0) THEN BEGIN
                tex[0,i] = t/(2.*!PI)
                tex[1,i] = (tz+(!PI/2.0))/(!PI)
            ENDIF

            t = t + tinc
            i = i + 1L
        ENDFOR
        tz = tz - tzinc
    ENDFOR
    top = i
    verts[0,i] = self.position[0]
    verts[1,i] = self.position[1]
    verts[2,i] = self.radius*1.0 + self.position[2]
    i = i + 1L
    bot = i
    verts[0,i] = self.position[0]
    verts[1,i] = self.position[1]
    verts[2,i] = self.radius*(-1.0) + self.position[2]

    IF (self.texture NE 0) THEN BEGIN
        tex[0,i] = 0.5
        tex[1,i] = 0.0
        tex[0,i-1] = 0.5
        tex[1,i-1] = 1.0
    ENDIF

    ; Fill in the connectivity array.
    i = 0
    FOR k=0,(nrows-2) DO BEGIN
        FOR j=0,(ncols-1) DO BEGIN
            conn[i] = 4

            conn[i+4] = k*ncols + j

            w = k*ncols + j + 1L
            IF (j EQ (ncols-1)) THEN w = k*ncols
            conn[i+3] = w

            w = k*ncols + j + 1L + ncols
            IF (j EQ (ncols-1)) THEN w = k*ncols + ncols
            conn[i+2] = w

            conn[i+1] = k*ncols + j + ncols

            i = i + 5L
            IF ((self.texture NE 0) AND (j EQ (ncols-1))) THEN $
                i = i - 5L
        ENDFOR
    ENDFOR
    FOR j=0,(ncols-1) DO BEGIN
        conn[i] = 3
        conn[i+3] = top
        conn[i+2] = j+1L
        IF (j EQ (ncols-1)) THEN conn[i+2] = 0
        conn[i+1] = j
        i = i + 4L
        IF ((self.texture NE 0) AND (j EQ (ncols-1))) THEN $
            i = i - 4L
    ENDFOR
    FOR j=0,(ncols-1) DO BEGIN
        conn[i] = 3
        conn[i+3] = bot
        conn[i+2] = j+(nrows-1L)*ncols
        conn[i+1] = j+(nrows-1L)*ncols+1L
        IF (j EQ (ncols-1)) THEN conn[i+1] = (nrows-1L)*ncols
        i = i + 4L
        IF ((self.texture NE 0) AND (j EQ (ncols-1))) THEN $
            i = i - 4L
    ENDFOR

    self.oPoly->SetProperty, DATA=verts, POLYGONS=conn

    IF (self.texture NE 0) THEN $
        self.oPoly->SetProperty, TEXTURE_COORD=tex
END

;----------------------------------------------------------------------------
; SUNORB__DEFINE
;
; Purpose:
;  Defines the object structure for a SunOrb object.
;
PRO sunorb__define
    struct = { sunorb, $
               INHERITS IDLgrModel, $
               position: [0.0,0.0,0.0], $
               radius: 1.0, $
               orbsize: 5.0, $
               texture: 0, $
               oPoly: OBJ_NEW() $
             }
END
