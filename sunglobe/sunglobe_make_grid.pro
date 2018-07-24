;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_MAKE_GRID()
;
; Purpose     :	Generates coordinate grid for SUNORB spheres
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	Generates a coordinate grid of longitude and latitude lines for
;               spheres created with sunorb__define.pro.  The longitude lines
;               are labelled along the equator, and the latitude lines are
;               labelled at 0, 90, 180, and 270 degrees longitude.
;
; Syntax      :	oResult = sunglobe_make_grid()
;
; Examples    :	osphere = obj_new('sunorb', /tex_coords, texture_map=oimage, $
;                  color=[255,255,255], radius=1.0)
;               omodelrotate->add, osphere
;               ogrid = sunglobe_make_grid()
;               omodelrotate->add, ogrid
;
; Inputs      :	None
;
; Outputs     :	The result of the function is the object graphics ID of the
;               coordinate grid.
;
; Keywords    :	GRIDCOLOR = Color to be used for drawing the grid and labels.
;                           Can be either a color index, or a 3-element color
;                           specification.  Default is [255,255,255] (white).
;
;               FONT    = Font object for coordinate labels.
;
;               CHAR_DIMENSIONS = Two element array containing the character
;                                 dimensions to use for the label, in data
;                                 units.  Default is [0.05, 0.05].
;
;               GRIDSIZE = Spacing between grid lines, in degrees.  Default is
;                          15 degrees.  Will be adjusted to fit neatly within
;                          90 degrees if necessary.
;
;               NGRIDPOINTS = Number of grid points used to draw each longitude
;                             and latitude line.  Default is 360.
;
; Calls       :	NTRIM
;
; History     :	Version 1, 11-Dec-2015, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_make_grid, font=ofont, gridsize=k_gridsize, $
                             gridcolor=gcolor, char_dimensions=chardim, $
                             ngridpoints=ngridpoints
;
;  Make a generic circle with points 360/NGRIDPOINTS degrees apart.
;
if n_elements(ngridpoints) eq 0 then ngridpoints = 360
dtor = !dpi / 180.d0
delta = dtor * (360.d0 / ngridpoints)
theta = [delta * dindgen(ngridpoints), 0]
xgrid = cos(theta)
ygrid = sin(theta)
;
;  Get the color.
;
case n_elements(gcolor) of
    1: color = gcolor
    3: color = gcolor
    else: color = [255,255,255]
endcase
;
;  Get the character dimensions.
;
case n_elements(chardim) of
    1: char_dimensions = replicate(chardim, 2)
    2: char_dimensions = chardim
    else: char_dimensions = [0.05, 0.05]
endcase
;
;  Make an object to contain the grid lines.
;
ogrid = OBJ_NEW('IDLgrModel')
;
;  Add the lines of longitude.  Make sure the grid lines fit neatly within 90
;  degrees.
;
if n_elements(k_gridsize) eq 0 then gridsize = 15.d0 else $
  gridsize = 90.d0 / round(90.d0 / k_gridsize)
longitude = 0.0d0
while longitude lt 180 do begin
    angle = dtor * longitude
    oline = OBJ_NEW('IDLgrPolyline', COLOR=color, $
                    xgrid*cos(angle), xgrid*sin(angle), ygrid)
    ogrid->ADD, oline
;
;  Add a label for the longitude.
;
    label = ' ' + ntrim(longitude)
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[ cos(angle), sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[sin(angle), -cos(angle)], BASELINE=[0,0,1])
    ogrid->ADD, otext
;
;  Add another label for the longitude + 180 degrees.
;
    label = ' ' + ntrim(longitude+180)
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[-cos(angle), -sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[-sin(angle), cos(angle)], BASELINE=[0,0,1])
    ogrid->ADD, otext
;
    longitude = longitude + gridsize
endwhile
;
;  Add the lines of latitude.  Start with the positive latitudes.
;
latitude = 0.0d0
while latitude lt 90 do begin
    angle = dtor * latitude
    radius = cos(angle)
    height = replicate(sin(angle), ngridpoints+1)
;
    oline = OBJ_NEW('IDLgrPolyline', COLOR=color, $
                    xgrid*radius, ygrid*radius, height)
    ogrid->ADD, oline
;
;  Add a label at 0 degrees longitude.
;
    label = ' ' + ntrim(latitude)
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[cos(angle), 0, sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[-sin(angle), 0, cos(angle)], BASELINE=[0,1,0])
    ogrid->ADD, otext
;
;  Add a label at 90 degrees longitude.
;
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[0, cos(angle), sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[0, -sin(angle), cos(angle)], BASELINE=[-1,0,0])
    ogrid->ADD, otext
;
;  Add a label at 180 degrees longitude.
;
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[-cos(angle), 0, sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[sin(angle), 0, cos(angle)], BASELINE=[0,-1,0])
    ogrid->ADD, otext
;
;  Add a label at 270 degrees longitude.
;
    otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                    LOCATION=[0, -cos(angle), sin(angle)], $
                    CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                    UPDIR=[0, sin(angle), cos(angle)], BASELINE=[1,0,0])
    ogrid->ADD, otext
;
;  Also draw lines for negative latitudes.
;
    if latitude ne 0 then begin
        label = ' ' + ntrim(-latitude)
        oline = OBJ_NEW('IDLgrPolyline', COLOR=color, $
                        xgrid*radius, ygrid*radius, -height)
        ogrid->ADD, oline
;
;  Add a label at 0 degrees longitude.
;
        otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                        LOCATION=[cos(angle), 0, -sin(angle)], $
                        CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                        UPDIR=[sin(angle), 0, cos(angle)], BASELINE=[0,1,0])
        ogrid->ADD, otext
;
;  Add a label at 90 degrees longitude.

        otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                        LOCATION=[0, cos(angle), -sin(angle)], $
                        CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                        UPDIR=[0, sin(angle), cos(angle)], BASELINE=[-1,0,0])
        ogrid->ADD, otext
;
;  Add a label at 180 degrees longitude.
;
        otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                        LOCATION=[-cos(angle), 0, -sin(angle)], $
                        CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                        UPDIR=[-sin(angle), 0, cos(angle)], BASELINE=[0,-1,0])
        ogrid->ADD, otext
;
;  Add a label at 270 degrees longitude.
;
        otext = OBJ_NEW('IDLgrText', label, COLOR=color, FONT=ofont, $
                        LOCATION=[0, -cos(angle), -sin(angle)], $
                        CHAR_DIMENSIONS=CHAR_DIMENSIONS, $
                        UPDIR=[0, -sin(angle), cos(angle)], BASELINE=[1,0,0])
        ogrid->ADD, otext
    endif
    latitude = latitude + gridsize
endwhile
;
return, ogrid
end
