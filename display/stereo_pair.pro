;+
; Project     :	STEREO - SECCHI
;
; Name        :	STEREO_PAIR
;
; Purpose     :	Create stereo image pair from two SECCHI or other files
;
; Category    :	STEREO, SECCHI, Registration
;
; Explanation : This routine is adapted from scc_stereopair.pro to extend most
;               of the functionality to other missions, such as Solar Orbiter.
;               This procedure creates coaligned image pairs from the two
;               spacecraft.  Each image is rescaled to a common center and
;               image size.  The orientation of the images are aligned for
;               proper stereo viewing.
;
; Syntax      :	Output = STEREO_PAIR( IMAGE_RIGHT, IMAGE_LEFT, $
;                               INDEX_RIGHT, INDEX_LEFT )
;
; Examples    :	SECCHI_PREP, FILES_RIGHT,  INDEXA, IMAGEA
;               SECCHI_PREP, FILES_LEFT, INDEXB, IMAGEB
;               Output = STEREO_PAIR( IMAGEA, IMAGEB, INDEXA, INDEXB )
;
; Inputs      :	IMAGE_RIGHT = Image(s) for the observatory on the right
;               IMAGE_LEFT  = Image(s) for the observatory on the left
;               INDEX_RIGHT = FITS index structure(s) for IMAGE_RIGHT
;               INDEX_LEFT  = FITS index structure(s) for IMAGE_LEFT
;
;               The order of the parameters in the call are defined to match
;               that used in scc_stereopair.pro.
;
; Opt. Inputs :	None
;
; Outputs     :	The result of the function is an array of images with
;               dimensions [2,Nx,Ny,Ni] where Output[0,*,*,*] are the left-eye
;               (Behind) images, and Output[1,*,*,*] are the right-eye (Ahead)
;               images.  Nx, Ny are the dimensions of each image, and Ni is the
;               total number of image pairs.
;
;               For historical reasons, the order of the output is reversed
;               from the order of the input.  To make the order match, use the
;               /REVERSE keyword.
;
;               INDEX_RIGHT, INDEX_LEFT are updated to reflect the coordinate
;               transformations.
;
; Opt. Outputs:	None.
;
; Keywords    :	REVERSE   = If set, reverse the order of the output to be
;                           right-left instead of left-right.
;
;               INTERP   = Interpolation type, 0=nearest neighbor, 1=bilinear
;                          interpolation (default), 2=cubic interpolation.
;
;               CUBIC    = Interpolation parameter for cubic interpolation.
;                          See the IDL documentation for POLY_2D for more
;                          information.
;
;               NOMISSING = If set, then don't filter out missing pixels around
;                           the edge of the CCD.
;
; Calls       :	FITSHEAD2WCS, WCS_GET_PIXEL, WCS2FITSHEAD, FITSHEAD2STRUCT,
;               PARSE_SUNSPICE_NAME, LOAD_SUNSPICE, GET_SUNSPICE_COORD
;
; Common      :	None.
;
; Restrictions:	Depends on the SunSPICE package.
;
; Side effects:	The returned index structures are updated to reflect the
;               image manipulations.  Only the primary WCS coordinate system
;               keywords are updated.  If there are other coordinate systems
;               within the header (e.g. CRPIX1A, CRVAL1A, etc.), these will no
;               longer be valid for the updated images.
;
; Prev. Hist. :	None.
;
; Written     :	21-Jul-2020, William Thompson, GSFC
;
; History     : Version 1, 21-July-2020, William Thompson, GSFC
;               Version 2, 23-July-2020, WTT, correct NAXIS1,NAXIS2
;
; Contact     :	WTHOMPSON
;-
;
function stereo_pair, image_right, image_left, index_right, index_left,$
                      interp=interp, reverse=reverse, $
                      left_template=left_template, _extra=_extra
;
on_error, 2
;
;  Check on the total number of parameters and images passed.
;
if n_params() lt 4 then message, $
   'Syntax: Result = STEREO_PAIR(IMAGE_RIGHT, IMAGE_LEFT, INDEX_RIGHT, INDEX_LEFT)'
szr = size(image_right)
case szr[0] of
   2:  n_images = 1
   3:  n_images = szr[3]
   else: message, 'IMAGE_RIGHT must have 2 or 3 dimensions'
endcase
szl = size(image_left)
case szl[0] of
   2:  n_img_l = 1
   3:  n_img_l = szr[3]
   else: message, 'IMAGE_LEFT must have 2 or 3 dimensions'
endcase
if n_images ne n_img_l then message, $
   'Arrays IMAGE_RIGHT and IMAGE_LEFT do not agree'
if n_images eq 0 then message, 'No images passed'
if (datatype(index_right) ne 'STC') or (datatype(index_left) ne 'STC') then $
   message, 'INDEX_RIGHT and INDEX_LEFT must be structures'
;
;  Get the INTERP value to pass to POLY_2D.
;
if n_elements(interp) eq 0 then interp = 1
;
;  Get the observatory ID numbers, and make sure that the ephemerides are
;  loaded.
;
obs = replicate('399', 2)
if tag_exist(index_right,'obsrvtry') then $
   obs[0] = parse_sunspice_name(index_right.obsrvtry, /earth_default)
load_sunspice, obs[0]
if tag_exist(index_left,'obsrvtry') then $
   obs[1] = parse_sunspice_name(index_left.obsrvtry, /earth_default)
load_sunspice, obs[1]
;
;  Copy the original headers into new arrays.
;
header_right = index_right
header_left  = index_left
if keyword_set(left_template) then begin
   header = header_left[0]
   sz = szl
end else begin
   header = header_right[0]
   sz = szr
endelse
;
;  Get the solar distance, the pixel spacing, and the pixel location of Sun
;  center.  All the other images will be matched to this.
;
wcs = fitshead2wcs(header)
dsun_obs0 = wcs.position.dsun_obs
cdelt0 = wcs.cdelt
pixel0 = wcs_get_pixel(wcs, [0,0])
;
;  Create the arrays of index structures to return.
;
if n_params() gt 2 then begin
    iindex = wcs2fitshead(wcs,old=header,/add_xcen,/add_roll,/structure)
    index_right  = replicate(iindex, n_images)
    index_left = index_right
endif
;
;  Create the output array.
;
type = sz[sz[0]+1]
dim = [2, sz[1:2]]
if n_images gt 0 then dim = [dim, n_images]
output = make_array(type=type, dimension=dim)
;
;  Select a missing value, based on the datatype.
;
case type of
    4: missing = !values.f_nan
    5: missing = !values.d_nan
    else: missing = 0
endcase
;
;  Resample each image so that each has the same Sun center and scale.  Rotate
;  the image by the roll angle to the epipolar plane formed by the Sun and the
;  two spacecraft.
;
p = dblarr(2,2)
q = dblarr(2,2)
for j=0,1 do begin
    if keyword_set(reverse) then jj = 1-j else jj = j
    for i=0,n_images-1 do begin
        if j eq 0 then begin
            header = header_left[i]
            image = image_left[*,*,i]
        end else begin
            header = header_right[i]
            image = image_right[*,*,i]
        endelse
        wcs = fitshead2wcs(header)
        pixel = wcs_get_pixel(wcs, [0,0])
        scale = (cdelt0 / wcs.cdelt) * (dsun_obs0 / wcs.position.dsun_obs)
        coord = get_sunspice_coord(header.date_obs, obs[1-j], system='rtn', $
                                   target=obs[j])
        roll = atan(coord[2], coord[1]) * 180.d0 / !dpi
        if j eq 1 then roll = 180 + roll
        roll = roll - wcs.roll_angle
        cosr = cos(roll * !dpi / 180.d0)
        sinr = sin(roll * !dpi / 180.d0)
;
;  Call POLY_2D to resample the image.
;
        p[0,0] = pixel[0] - scale[0]*pixel0[0]*cosr + scale[1]*pixel0[1]*sinr
        q[0,0] = pixel[1] - scale[0]*pixel0[0]*sinr - scale[1]*pixel0[1]*cosr
        p[0,1] =  scale[0]*cosr
        p[1,0] = -scale[1]*sinr
        q[0,1] =  scale[1]*sinr
        q[1,0] =  scale[0]*cosr
        output[jj,*,*,i] = poly_2d(image, p, q, interp, missing=missing, $
                                   sz[1], sz[2], _extra=_extra)
;
;  Modify the WCS structure to reflect the new image scale.
;
        if n_params() gt 2 then begin
            wcs.crpix = pixel0
            wcs.crval[*] = 0
            wcs.cdelt = wcs.cdelt * scale
            wcs.roll_angle = wcs.roll_angle + roll
            cos_a = cos(wcs.roll_angle * !dpi / 180.d0)
            sin_a = sin(wcs.roll_angle * !dpi / 180.d0)
            lambda = wcs.cdelt[1] / wcs.cdelt[0]
            wcs.pc[0,0] = cos_a
            wcs.pc[0,1] = -lambda * sin_a
            wcs.pc[1,0] = sin_a / lambda
            wcs.pc[1,1] = cos_a
            iindex = wcs2fitshead(wcs, old=header, /add_xcen, /add_roll, $
                                  /structure)
            if j eq 0 then temp = index_left[i] else temp = index_right[i]
            struct_assign, iindex, temp
            temp.naxis1 = sz[1]
            temp.naxis2 = sz[2]
;
;  Store the modified header.
;       
            if j eq 0 then index_left[i] = temporary(temp) else $
              index_right[i] = temporary(temp)
        endif
    endfor
endfor
;
return, output
end
