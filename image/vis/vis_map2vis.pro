;+
; PROJECT:
;   ssw/gen/idl/image
;
; NAME:
;   vis_map2vis, map, xy, uv
;
; PURPOSE:
;   Returns an array of visibility structures corresponding to an input map defined on a square array of pixels
;
; CATEGORY:
;   image
;
; CALLING SEQUENCE:
;   visarray = vis_map2vis(map, xy, uv)
;   See vis_map2vis_test.pro for a testing sequence
;
; Example:
;  obj = hsi_image( image_alg = 'pixon' )
;
;  obj-> set, im_time_interval= ['20-Feb-2002 11:05:58.000', '20-Feb-2002 11:06:21.000']
;  obj-> set, im_energy_binning = [ 12., 25. ]
;  obj-> set, det_index_mask = [0, 0, bytarr(6)+1b, 0], /use_phz_stacker
;  obj-> set, pixel_size = [1., 1.]
;
;  ;  set the control parameters as you please
;  imgc = obj->getdata() ;image is on a Cartesian grid
;  imga = obj->getdata( class = 'hsi_pixon' ) ;image is on on the anssec coordinates
;  imga /= obj->get(/alg_unit_scale)
;  ;   imgc is interpolated from imga
;  ;   We can make visibilities from either image
;  ;   Suppose we want all the possible visibility U and V for the current configuration
;  ;   Make a visibility object and get all of the visibility using /DUMP
;  ov = obj->get( /obj, class='hsi_visibility' )
;  vis= ov->getdata(/dump)
;  help, vis
;  ;  VIS             STRUCT    = -> HSI_VIS Array[400]
;  ;  Two ways to get the coordinate system for the annsec image, i.e. imga
;  ;  1. If you have the object as we do here:
;  hsi_annsec_coord, obj, x, y, xy_s = xy
;  ;   IDL> help, xy
;  ;   ** Structure <2064b410>, 2 tags, length=34840, data length=34840, refs=1:
;  ;   X               FLOAT     Array[65, 67]
;  ;   Y               FLOAT     Array[65, 67]
;  ;   1. If you don't have the object you can still build the coordinate system
;  xyoffset = vis[0].xyoffset
;  xya = hsi_annsec_par2xy( xyoffset, pixel_size = [1., 1.])
;  ;   IDL> help, xya, xy
;  ;    XYA             STRUCT    = -> <Anonymous> Array[1]
;  ;    XY              STRUCT    = -> <Anonymous> Array[1]
;  ;    IDL> help, xya, xy,/st
;  ;    ** Structure <2064b5e0>, 2 tags, length=34840, data length=34840, refs=1:
;  ;    X               FLOAT     Array[65, 67]
;  ;    Y               FLOAT     Array[65, 67]
;  ;    ** Structure <2064b410>, 2 tags, length=34840, data length=34840, refs=1:
;  ;    X               FLOAT     Array[65, 67]
;  ;    Y               FLOAT     Array[65, 67]
;  ;    IDL> pmm, xya.x-xy.x, xya.y-xy.y
;  ;    % Compiled module: PMM.
;  ;    0.000000     0.000000
;  ;    0.000000     0.000000
;  ;    Once we have the coordinate system  we can obtain the visibility amplitudes for the spatial frequencies from the Annsec Image
;  ;    and the corresponding vis amps from the Cartesian Map just using the visibilities, VIS.
;  va = vis_map2vis( imga, xya, vis )
;  vc = vis_map2vis( imgc, dummy, vis )
;  ;    IDL> help, va
;  ;    VA              STRUCT    = -> HSI_VIS Array[400]
;  ;    IDL> help, va,/st
;  ;    ** Structure HSI_VIS, 15 tags, length=112, data length=102:
;  ;    ISC             INT              0
;  ;    HARM            INT              1
;  ;    ERANGE          FLOAT     Array[2]
;  ;    TRANGE          DOUBLE    Array[2]
;  ;    U               FLOAT          0.220757
;  ;    V               FLOAT         0.0105845
;  ;    OBSVIS          COMPLEX   (      7.28559,      11.1368)
;  ;    TOTFLUX         FLOAT          0.000000
;  ;    SIGAMP          FLOAT           245.240
;  ;    CHI2            FLOAT           1.00000
;  ;    XYOFFSET        FLOAT     Array[2]
;  ;    TYPE            STRING    'photon'
;  ;    UNITS           STRING    'Photons cm!u-2!n s!u-1!n'
;  ;    ATTEN_STATE     INT              1
;  ;    COUNT           FLOAT           10764.4
;  ;
;  ;   Finally, va and vc compare them mid-range
;  print, va[200:209].obsvis
;  ;    (     -9.83602,      9.90639)(     -35.7409,      8.78447)(     -56.8561,     -4.54496)(     -68.7383,     -25.4264)(     -69.9525,     -48.3092)(     -61.7509,     -68.4882)
;  ;    (     -47.0511,     -83.1171)(     -29.2901,     -91.3545)(     -11.5687,     -93.8719)(      3.77340,     -92.0994)
;  print, vc[200:209].obsvis
;  ;    (     -9.52532,      10.2607)(     -35.4102,      8.92325)(     -56.8587,     -4.55858)(     -68.9933,     -25.2391)(     -70.1391,     -47.6571)(     -61.6791,     -67.4477)
;  ;    (     -46.7752,     -82.0252)(     -28.9690,     -90.5566)(     -11.3424,     -93.5219)(      3.77521,     -92.0913)
;  ;
;
; CALLS:
;   none
;
; INPUTS:
;   MAP is an nx x ny -element square array specifying the flux (photons/cm2/s) at nx x ny spatial points.
;   XY may be a 2 x nx element array specifying the E,N displacements in arcseconds of the map axes.
;		In this case the map must be square.
;		Or, XY may be a structure with two fields x and y specifying the information  but allowing for different
;		sizes in x and y. Origin is arbitrary.
;		if XY is a variable and doesn't have 2 dimensions, the coordinates are derived from the map array
;		with an assumed spacing of 1 arcsecond
;      OR
;	map may be input as a map structure. In this case, map.data is used for the map and the xy
;		xy array is constructed from the map coordinates
;   UV  may be a visibility bag and the u and v will be set to the values derived from the visibilities in
;   the bag.
;		sigamp and chi2 will be set as below. Other tags will have their default values except for trange
;		and erange which will retain their values. By this method, this routine can be used
;		unmodified for STIX and any imagined configuration of uv without any rhessi dependency
;
;	UV  may also be a 2 x nuv element array specifying the u and v values [arcsec^-1] at which the visibilities
;       are to be calculated.  The default for this is to assign these uv based on the RHESSI configuration.
;       nuv is the number of joint u and v elements in the bag or passed array
;		Also, the uv array may be used for any configuration by ignoring the ISC field and changing
;		it outside of this routine.
;		For non-RHESSI uv, the visibility bag input should be used
;
;
; OPTIONAL INPUTS:
;   LOOPSTYLE - Keyword, if set make the computation the old way, prior to 15-apr-2013, using a do loop
;		to make the actual computation of the vis bag.  Otherwise use the vectoral implementation which
;		is formally identical. Loopstyle cannot be used with XY structure input
;	VIS_STR - Keyword, default is to use a {hsi_vis} structure but you can use any vis structure that
;		is compliant. Values of isc won't be set.
;		** Structure HSI_VIS, 15 tags, length=104, data length=94:
;		   ISC             INT              0
;		   HARM            INT              0
;		   ERANGE          FLOAT     Array[2] 						Required
;		   TRANGE          DOUBLE    Array[2]
;		   U               FLOAT          0.000000					Required
;		   V               FLOAT          0.000000					Required
;		   OBSVIS          COMPLEX   (     0.000000,     0.000000)  Required
;		   TOTFLUX         FLOAT          0.000000
;		   SIGAMP          FLOAT          0.000000					Required
;		   CHI2            FLOAT          0.000000					Required
;		   XYOFFSET        FLOAT     Array[2]						Required
;		   TYPE            STRING    ''
;		   UNITS           STRING    ''
;		   ATTEN_STATE     INT              0
;		   COUNT           FLOAT          0.000000
;   PIXEL - keyword, pixel size in arcseconds. used to define map coordinates if a flat array is passed
;     without the coordinate vectors in XY. If PIXEL is defined and positive and a flat array is passed
;     this will be used instead of XY to define the coordinates
; OUTPUTS:
;   Returns an nuv-element array of standard visibility structures created by {hsi_vis}.
;       See visibilityguide.pdf for a description of the tags in this array.
;
;   Mapcenter is set to the centerpoint of the provided map coordinates.  Mapcenter tags are set accordingly.
;   Subcollimator number is inferred from the spatial frequency and the isc tags are set accordingly.
;   The harmonic is assumed to be 1 and the harmonic tags are set accordingly.
;   chi2 tags are arbitrarily set to 1.
;   sigamp tags are arbitrarily set to 10% of the largest amplitude.
;   erange tags are arbitrarily set to [1,2].
;
; OPTIONAL OUTPUTS:
;   none
;
; SIDE EFFECTS:
;   none
;
; RESTRICTIONS:
;   sigamp, chi2 tags should be overwritten by the calling program if errors are relevant.
;   erange tags should be overwritten by the calling program.
;   trange, totflux, tags should be set subsequently by the calling program.
;   negative values in the input map are ignored
;
; MODIFICATION HISTORY:
; Based on HSI_VIS_MAP2VIS
;	15-apr-2013, ras, changed do loop over obsvis to a vector expression
;		using # and ## operators. On a dense map, it can improve the speed by up to 4x
;		there is no difference on simple maps, allow input of map structure
;
;	19-jul-2013, added pixel as keyword
;	22-nov-2013, ras, removed erange check for non-zero. It has no business here and can only cause trouble
;	21-Mar-2017, Kim. Previously stopped in routine on error conditions. Now print message and return -1.
;	17-apr-2017, RAS, suppressed message about negative values in map, just ignore them
;	  added documentation for map on arbitrary set of x and y coordinates even if not a grid
;	12-jul-2018, RAS, added "else begin" block so LOOPSTYLE will actually be used! Otherwise,
;	LOOPSTYLE result is just overwritten, also fixed bug introduced in april 2017 whch let negative map
;	values get included in the vis amplitude computation
;	13-jul-2018, RAS, unifying the phase computation by casting x and y into the same shape 
;-
FUNCTION vis_map2vis, map, xy, uv, LOOPSTYLE=LOOPSTYLE, VIS_STR = vis_str, PIXEL = pixel, phases = phases
  ;
  default, loopstyle, 0
  twopi           = 2 * !pi
  if is_struct( map ) then begin ;using a map structure carries all the information
    map_data = map.data
    dim = size(/dim, map_data)
    x = mk_map_xp( map.xc, map.dx, dim[0])
    y = mk_map_xp( map.yc, map.dy, dim[1]) ;mk_map_xp lets you make the 1d coord

  endif else begin
    map_data = map
    if fcheck(pixel, 0.0) gt 1e-7 then begin
      dim = size(/dim, map_data)
      x = mk_map_xp( 0.0, pixel[0], dim[0] )
      y = mk_map_xp( 0.0, pixel[0], dim[1] )
    endif
  endelse
  ;Configure x and y displacement vectors.  They don't need to be of equal size
  ;Nothing here says the map must be square
  if ~exist(x) then $ ;If x not defined from the map, then we have to build it
    if 	is_struct(xy)  then begin ;old style coordinates
    ;xy.x may be explicit x and y values for each map pixel
    ;mandatory for a non-uniform grid, assumes near-uniform pixel size
    x = xy.x
    y = xy.y
  endif else begin
    dimxy = size(/dim, xy)
    ndimxy = n_elements(dimxy)
    dim_map = size(/dim, map_data)
    if ndimxy eq 2 then begin
      if (dimxy[0] ne 2) or (dimxy[1] ne n_elements(map_data[*,0])) then begin
        message, 'Inconsistent input dimensions', /info
        return, -1
      endif
      x = reform(xy[0,*])
      y = reform(xy[1,*])
    endif else begin ;No dimensions given but we can use the flat map
      x  = mk_map_xp( 0.0, 1.0, dim_map[0])
      y  = mk_map_xp( 0.0, 1.0, dim_map[1])
    endelse
  endelse
  nuv             = n_elements(uv)/2
  nx              = n_elements(x)
  ny              = n_elements(y)
  mapcenterx      = nx/2*2 eq nx ? average(x[nx/2-1:nx/2]) : x[nx/2]
  mapcentery      = ny/2*2 eq ny ? average(y[ny/2-1:ny/2]) : y[ny/2]

  ;  dummy = where(map_data lt 0, nneg)
  ;  IF nneg GT 0 then message, 'Map has one or more negative pixels.',/info

  If ~is_struct( uv ) then begin
    default, vis_str, {hsi_vis}
    vis_name = size(/sname, vis_str[0] )
    visout          = replicate( vis_str, nuv)            ; creates an array of standard visibility structures
    visout.u        = reform(uv[0,*])
    visout.v        = reform(uv[1,*])
    if stregex( vis_name, /fold, /boolean, 'hsi_vis') then begin
      spatfreq2       = ((visout.u^2 + visout.v^2)*2.33^2)
      scn             = round(-alog(spatfreq2) / alog(3))
      visout.isc      = scn-1                                 ; assuming harm=1
      visout.harm     = 1                                     ; assumption
    endif
    visout.chi2     = 1.                                    ; arbitrary !!!!!
    visout.xyoffset = [mapcenterx, mapcentery]
    uv_use          = uv ;so we're sure not to overwrite the incoming uv in the next step
  endif else begin
    ;We've passed in a structure, we only need to replace some of the fields, notably obsvis
    visout          = uv

    if tag_exist( visout, 'chi2') then visout.chi2     = 1.
    visout.totflux  = 0.0
    uv_use          = transpose( [[visout.u], [visout.v]] )
    ;if another non-zero mapcenter was passed in via xy then use it, otherwise use the incoming
    visout.xyoffset = (mapcenterx ne 0.0) or (mapcentery ne 0.0) ? [mapcenterx, mapcentery] : visout.xyoffset
  endelse

  ;
  ; Begin loop over nonzero pixels.
  ok  = where(map_data ge 0, nok, ncomp = nltz) ;previous bug had where( map_data > 0 ge0, nok) -ie all treated as + when some are -
  ic  = complex(0.0, 1.0) ; imaginary 1
  if nok eq 0 then begin
    message, 'Empty Map', /info
    return, -1
  endif
  if loopstyle and size( /n_dim, x ) eq 2 then begin
    message, 'Cannot use LOOPSTYLE method with 2d X and Y pixel info',/info
    return, -1
  endif
  if loopstyle then for n=0l, nok-1 do begin
    ij              = array_indices(map_data, ok[n])                      ; 2-element vector with indices corresponding to nonzero map points
    phase           = twopi * (uv_use[0,*]*(x[ij[0]]-mapcenterx) + uv_use[1,*]*(y[ij[1]]-mapcentery))             ; nuv_use-element vector
    visout.obsvis   = visout.obsvis + map_data[ok[n]] * complex(cos(phase), sin(phase))     ; nuv-element complex vector
  endfor else begin ;added else begin, ras, 12-jul-2018
    ;we can replace the previous loop with this compact expression which does exactly the same
    if size( x, /n_dimension ) eq 1 then begin
      ij = array_indices( map_data, lindgen( n_elements( map_data ) ))
      x  =  x[ij[0,*]]
      y  =  y[ij[1,*]]
    endif
    phases = twopi * ( reform(uv_use[0,*]) # ( x[ok] - mapcenterx ) + reform(uv_use[1,*]) # ( y[ok] - mapcentery))
    visout.obsvis  =  map_data[ok] ## exp( ic * phases )
  endelse
  sigamp = 0.1 * max(abs(visout.obsvis))
  visout.sigamp = sigamp                                  ; arbitrary !!!
  if tag_exist( visout, 'erange') && total(visout.erange) eq 0 then visout.erange = [1,2]			;if nonzero we have an erange
  return, visout
end
