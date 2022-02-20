;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_READ_CONNECTFILE()
;
; Purpose     :	Read in output from the Magnetic Connectivity Tool
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation :	This routine reads in an ASCII output file from the Magnetic
;               Connectivity Tool (http://connect-tool.irap.omp.eu/), and
;               formulates it into an image overlay for SunGlobe.  Connectivity
;               points for fast solar wind are displayed in red, slow solar
;               wind in blue, and measured solar wind in green.
;
; Syntax      :	Result = SUNGLOBE_READ_CONNECTFILE(GROUP_LEADER=GROUP_LEADER)
;
; Examples    :	See 
;
; Inputs      :	None
;
; Opt. Inputs :	None
;
; Outputs     :	The result of the function is a structure containing the
;               following parameters.
;
;               DATE    = The date associated with the map.
;
;               SPACECRAFT = The spacecraft associated with the map.  This can
;                            be checked against the spacecraft currently being
;                            used as the viewpoint within SunGlobe.
;
;               MAP     = The map read in from the file.
;               MAPMASK = An opacity map.  All points without data are
;                         transparent.
;               MAP_ROT = A placeholder for a rotated map.
;               MAPMASK_ROT = A placeholder for a rotated opacity map.
;               MAP_ALPHA = Map with alpha channel for opacity
;               OMAP_ALPHA = Map graphics object.
;
;               If no maps were read in, then 0 is returned.
;
; Opt. Outputs: None
;
; Keywords    : GROUP_LEADER = The widget ID of the group leader.
;
; Calls       :	XPICKFILE, XACK
;
; Restrictions: None
;
; History     :	Version 1, William Thompson, 08-Apr-2019, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_read_connectfile, group_leader=group_leader
;
;  Define a dummy result in case of error, and set up error catching.
;
result = 0
catch, error_status
if error_status ne 0 then begin
    catch, /cancel
    xack, !error_state.msg
    goto, cleanup
endif
;
;  Select a file to read in.
;
filename = xpickfile(group=group_leader, filter='*.ascii')
if filename eq '' then begin
    catch, /cancel
    xack, 'No file selected', group=group_lead
    return, 0
endif
;
;  Open the file, and skip over the header lines.
;
openr, unit, filename, /get_lun
line = 'string'
repeat readf, unit, line until strmid(line,0,1) ne '#'
;
;  Get the version number.
;
version = fix(line)
;
;  Get the solar radius.
;
rsun = 0.0
readf, unit, rsun
;
;  Get the date
;
date = 'string'
readf, unit, date
;
;  Get the spacecraft and its position.
;
readf, unit, line
words = strsplit(line, /extract)
nwords = n_elements(words)
spacecraft = words[0]
for i=1,nwords-4 do spacecraft = spacecraft + ' ' + words[i]
pos = double(words[nwords-3:*])
;
;  Get the total number of points to read in.
;
readf, unit, line
words = strsplit(line, /extract)
npts = fix(words[0])
;
;  Set up arrays for the parameters to be read in.
;
type    = strarr(npts)
density = dblarr(npts)
crlt    = dblarr(npts)
crln    = dblarr(npts)
;
;  Read in the lines.  If the file version is zero, then the type is not
;  included in the file, and is assumed to be "M" (measured).
;
for i=0,npts-1 do begin
    readf, unit, line
    words = strsplit(line,/extract)
    if version eq 0 then begin
        type[i] = 'M'
        density[i] = double(words[1])
        crlt[i]    = double(words[3])
        crln[i]    = double(words[4])
    end else begin
        type[i]    = words[0]
        density[i] = double(words[2])
        crlt[i]    = double(words[4])
        crln[i]    = double(words[5])
    endelse
endfor
;
;  Close the file.
;
free_lun, unit
;
;  Convert the densities into a map for the fast (red), measured (green), and
;  slow (blue) solar wind.
;
map = fltarr(3, 360, 180)
w = where(type eq 'FSW', count)         ;Fast solar wind, red channel
for i=0,count-1 do begin
    j = w[i]
    map[0, round(crln[j]) mod 360, round(crlt[j]+90)] += density[j]
endfor
;
w = where(type eq 'M', count)           ;Measured solar wind, green channel
for i=0,count-1 do begin
    j = w[i]
    map[1, round(crln[j]) mod 360, round(crlt[j]+90)] += density[j]
endfor
;
w = where(type eq 'SSW', count)         ;Slow solar wind, blue channel
for i=0,count-1 do begin
    j = w[i]
    map[2, round(crln[j]) mod 360, round(crlt[j]+90)] += density[j]
endfor
;
;  Scale the image, and form the mask.  Use ^0.3 to make the data more
;  visible.
;
mapmask = byte(total(map ne 0, 1))
map = bytscl(map^0.3)
w = where(mapmask ne 0, count)
if count gt 0 then mapmask[w] = 255b
sz = size(map)
;
;  Create a version of the map with an alpha channel, and define the alpha
;  channel based on the mask and opacity.  Form an image object.
;
sz = size(map)
map_alpha = bytarr(4,sz[2],sz[3])
map_alpha[0:2,*,*] = map
map_alpha[3,*,*] = mapmask
omap_alpha = obj_new('idlgrimage', map_alpha, location=[-1,-1], $
                     dimension=[2,2], blend_function=[3,4])
;
;  Create dummy rotated versions of MAP and MAPMASK.  These will be updated in
;  SUNGLOBE_DIFF_ROT.
;
map_rot = map
mapmask_rot = mapmask
;
;  Return the result as a structure.
;
result = {date: date, $
          spacecraft: spacecraft, $
          opacity: 1.0, $
          map: map, $
          mapmask: mapmask, $
          map_rot: map_rot, $
          mapmask_rot: mapmask_rot, $
          map_alpha: map_alpha, $
          omap_alpha: omap_alpha}
;
;  Return the result.
;
cleanup:
return, result
end
