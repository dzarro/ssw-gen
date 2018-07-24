;+
; Project: RHESSI
;
; Name: get_image_ellipse
;
; Purpose: Return ellipse properties of subregions in an image.
;
;
; Input keywords:
;   image - full image
;   xaxis - x coordinate of the center of each pixel in image in data units (like arcsec)
;   yaxis - y coordinate of the center of each pixel in image in data units (like arcsec)
;   boxes - array of box boundary information (2xn). boxes[0,*] are x coordinates,
;     boxes[1,*] are y coords.  In data units (same units as xaxis,yaxis). Used
;     with nperbox.
;   nperbox - array of number of elements in boxes to use for each box
;   inverse - if set, then use area outside boxes instead of within boxes
;
; Example:  if boxes is dimensioned (2,20) and nperbox=[5,15] then there are two boxes;
;   the first box has edge coordinates in boxes[*,0:4] and the second
;   box is defined by edge coordinates in boxes[*,5:19]
; Output:
;   Structure array (one per input box) containing:
;      major, minor - major, minor axis of ellipse in same units as xaxis,yaxis
;      position_angle - angle of ellipse for each box, in degrees, counter-clockwise from positive x axis 
;   Any box that didn't have enough pixels to use will return -1 for those values.
;
; Written: Rick Pernak, Kim Tolbert. Jan 2008
; Modifications:
;  13-Sep-2017, Kim. Changed doc header describing position_angle output. We're rotating the image
;    clockwise and looking for largest extent in x, so the image angle reported is actually counter-clockwise
;    from the pos x axis (previously said clockwise from North). Determination of position angle needs work -
;    need to fit a curve (or something) to find peak of dx curve instead of just finding max (smoothing doesn't help).
;-


function get_image_ellipse, image=image, $
  xaxis=xaxis,yaxis=yaxis, $
  boxes=boxes, nperbox=nperbox, inverse=inverse, $
  help=help


  if keyword_set(help) then begin
    print,'PURPOSE:'
    print,'	Find the ellipse properties of regions in an image.'
    print,'	USES 60% CONTOUR TO ELIMINATE TERTIARY SOURCES, WHICH ALTER SOURCE SIZE'
    print,'HELP:'
    print,'	pro get_image_ellipse,image=image, $
      print,'   xaxis=xaxis,yaxis=yaxis, $
      print,'   boxes=boxes, nperbox=nperbox, inverse=inverse, $
      print,'   help=help'
    print,'	inputs:	image (map of flare, dim x dim integer array)'
    print,' ...
    print,'	outputs:structure array (one per input box) containing:
    print,'   major - length of major axis in same units as x axis'
    print,'	  minor - length of minor axis in same units as y axis'
    print,'	  pa - position angle in degrees'
    print,'AUTHOR:'
    print,'	Rick Pernak, Goddard Space Flight Center'
    return, -1
  endif

  nbox = n_elements(nperbox)

  ;initialize output arrays
  major = dblarr(nbox) - 1.
  minor = dblarr(nbox) - 1.
  pa = intarr(nbox) - 1.

  ;initialize delta x arrays
  dx = dblarr(360)
  dy = dblarr(360)

  xpixel = xaxis[1] - xaxis[0]
  ypixel = yaxis[1] - yaxis[0]

  dim = size(image, /dim)
  nx = dim[0] & ny = dim[1]

  i1 = 0
  for ibox = 0,nbox-1 do begin
    ;i1,i2 are indices in boxes array to use for this box
    i2 = i1 + nperbox[ibox] - 1
    box = boxes[*,i1:i2]

    ; get indices in image contained in ROI defined by box
    index_1d = find_box_region_index (xaxis, yaxis, box)

    if index_1d[0] ne -1 then begin
      ; if inverse is set, then ind_use will be indices outside the box
      ind_box = intarr(nx,ny)
      ind_box[index_1d] = 1
      ind_use = keyword_set(inverse) ? where(ind_box eq 0) : where (ind_box eq 1)
      if ind_use[0] ne -1 then begin

        ; make a map filled with min of image, and then fill in indices we want to
        ; use (inside box) with actual image values
        map = fltarr(nx,ny) + min(image)
        map[ind_use] = image[ind_use]


        ; find limits of rectangle containing full part of image we're interested in
        ; and make map that subset.
        xr = minmax(ind_use mod nx)
        yr = minmax(ind_use / ny)
        map = map[xr[0]:xr[1], yr[0]:yr[1]]
        dim = size(map, /dim)
        nx1 = dim[0] & ny1 = dim[1]

        ; rotate the subset map a full 360 degrees in 1 degree increments saving
        ; the sigma at each angle
        for ctr=0,359 do begin
          deg = ctr + 1
          rmap = rot(map,deg)

          ;fetch coordinates of the 60% contour for each footpoint
          contour,rmap,lev=.6*max(rmap),/path_double,/path_data,path_xy=path

          ;find indices that are within the contour path
          fill = find_box_region_index(findgen(nx1), findgen(ny1), path)

          ;convert from 1-D array to 2-D array, yielding new map x and y coordinates
          mapx = fill mod nx1
          mapy = fill / ny1

          ;average of the coordinates
          mx = mean(mapx)
          my = mean(mapy)

          ;normalized intensities of the pixels (for weighting in sigma calculation)
          ;wgt = rmap[mapx,mapy]/max(rmap[mapx,mapy])
          wgt = rmap[fill]/max(rmap[fill])

          ;delta x, sigma x, whatever you wanna call it (deduced from variance)
          dx[ctr] = sqrt( total((mapx - mx)^2d * wgt)/nx1 )
          dy[ctr] = sqrt( total((mapy - my)^2d * wgt)/ny1 )
        endfor

        ; major and minor axes are twice the max and min sigma * pixel size
        major[ibox] = 2. * max(dx, indmax) * xpixel
        minor[ibox] = 2. * min(dx) * ypixel
        pa[ibox] = indmax ;pa[0] + 180 degrees is also a solution

      endif
    endif

    i1 = i1 + nperbox[ibox]
  endfor

  return, {major: major, minor: minor, pa: pa}
end