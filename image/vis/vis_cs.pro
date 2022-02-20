;+
; Name        : VIS_CS
;
; Purpose     : Run compressed sensing image reconstruction algorithm on RHESSI visibilities
;
; Inputs      : visibilities = RHESSI visibilities, with the required fields 'obsvis', 'sigamp', 'totflux', 'isc'
;               image_dim = default is [65,65], 2d array [width, height] with the desired dimensions of the reconstructed image;
;               Sparseness = optional 0..1, default 0.5. Smaller values provide more details, but are prone to over-resolution. Larger values lead to reconstructions lacking details.
;               pixel_size = optional, default 1 or [1,1]. Can be 1d or 2d array. Pixel size in arcseconds
;               abort_numerical_issues = optional 0/1, default 0. Controls whether the algorithm results a null-result instead of a partial result when encountering numerical issues. 
;               Verbose = optional 0/1, default 0. Controls whether print outputs are made.
;
; Returns     : Struct with {
;                 res      = image in the flux domain (2d array)
;                 version  = '2.0'
;               }
;
; Paper       : https://arxiv.org/abs/1709.08116
;
; History     : 20 Jan 2017, Roman Bolzern (FHNW)
;               - initial release
;               05 May 2017, Roman Bolzern (FHNW)
;               - added pixel_size
;               11 May 2017, Roman Bolzern (FHNW)
;               - added internal algorithm parameters
;               29 Aug 2017, Roman Bolzern (FHNW)
;               - improved photometry by total flux hard constraint
;               - more consistent reconstruction times due to changed thresholding
;               - moved AllowAsymmetric to internal params
;               - changed to version tag '2.0'
;               20 Oct 2017, Richard Schwartz (GSFC) 
;               - cleaned up the blocking and spacing, made image_dim a Keyword param, used default
;               25 Oct 2017, Richard Schwartz (GSFC)
;               - changed the method of sc selection from where to histogram with reverse indices
;               07  Oct 2019, Simon Felix  (FHNW)
;               - added optional parameter "abort_numerical_issues"
;
; Contact     : simon.felix@fhnw.ch
;
; See https://www.cs.technik.fhnw.ch/ircs/IDLModule for more information
;-

function VIS_CS, visibilities, $
  image_dim = image_dim, Sparseness = Sparseness, pixel_size = pixel_size, Verbose = Verbose, abort_numerical_issues = abort_numerical_issues, internalParams = internalParams

  default, Sparseness, 0.5
  default, pixel_size, 1.0
  default, Verbose, 0
  default, image_dim, [65, 65]
  default, abort_numerical_issues, 0

  if n_elements(pixel_size) EQ 1 THEN pixel_size = [pixel_size, pixel_size]

  IF N_Elements(internalParams) EQ 0 THEN BEGIN
    internalParams = { $
      elementsBaseCount: 200000, $
      maxAnisotropy: 2.5, $
      minSigma: 1.5d, $
      maxSigma: 60d, $
      seed: RANDOMU(abcdef), $
      iterations: 2, $
      lambda: 1000d, $
      allowAsymmetric: 1 $
    }
  ENDIF

  version = '2.0'
  if Verbose eq 1 then print, '-- VIS_CS version ' + version + ' --'

  W = ULONG(image_dim[0]) ; if not ULONG then int*int= max 32k, i.e. width/height could maximally be floor(sqrt(32767))=181
  H = ULONG(image_dim[1])
  W_arcsec = W * pixel_size[0]
  H_arcsec = H * pixel_size[1]

  MinSigma = internalParams.minSigma
  MaxSigma = internalParams.maxSigma
  MaxAnisotropy = internalParams.allowAsymmetric EQ 1 ? internalParams.maxAnisotropy : 1d

  if n_elements(visibilities) le 1 then begin
    print, '! There are no visibilities !'
    return, {res: fltarr(W, H), version: version}
  endif

  index = where(Finite(visibilities.totflux) $
    and ~(visibilities.obsvis eq complex(0.0,0.0) and visibilities.sigamp eq 0.0) $
    and visibilities.totflux ne 0.0, /NULL)

  if index EQ !NULL then begin
    print, '! Invalid visibilities: All have Im=0 && Re=0 && Sigamp=0 or TotalFlux=0 !'
    return, {res: fltarr(W, H), version: version}
  endif

  visibilities = visibilities[array_indices(visibilities, index)]

  res = fltarr(W, H)

  ITER = internalParams. iterations
  Elements = internalParams.elementsBaseCount / N_ELEMENTS(visibilities)

  seed = internalParams.seed

  dict = vis_cs_gaussdict_create(W, H, MinSigma, MaxSigma, MaxAnisotropy, Elements, pixel_size, RANDOMU(seed, 1))

  ;rick's method
  ;totalFlux = _visibilities.GroupBy(v => v.Detector).Select(g => g.Average(v => v.TotalFlux)).Average();
  ;var totalFlux = detectorTotalFlux.Values.Average();
  ;_iscl = visibilities.isc
  ;iscs = get_uniq( visibilities.isc ) ;_iscl[ UNIQ(_iscl, SORT(_iscl)) ]
  ;_tFarr = fltarr(n_elements(iscs))
  ;for i=0,n_elements(iscs)-1 do _tFarr[i] = mean(visibilities[ where(visibilities.isc eq iscs[i]) ].totflux)
  ;totalFlux = mean(_tFarr)
  ;Use the histogram function with reverse indices to obviate the need of calling where inside of a loop
  hisc = histogram( visibilities.isc, reverse_indices = risc ) ; get the used sub-colls and average totalflux
  zsc  = where( hisc ge 1, nzsc )
  _tFarr = fltarr( nzsc )
  for i = 0, nzsc -1 do _tFarr[i] = mean( visibilities[ reverseindices( risc, zsc[i] ) ].totflux )
  totalFlux = mean( _tFarr )
  

  for iteration=0,ITER-1 do begin

    uwf = vis_cs_coordinate_descent(W_arcsec, H_arcsec, dict, visibilities, totalFlux, sparseness, verbose, abort_numerical_issues, internalParams)
    limit = max([1d-8, (uwf[ reverse(sort(uwf)) ])[200]])
    wordsquery = where(uwf gt limit, /NULL)

    if Verbose eq 1 then print, "Words: " + strcompress(string(n_elements(wordsquery)))

    if iteration eq ITER-1 then begin
      res = vis_cs_gaussdict_render(dict[wordsquery], W, H, uwf[wordsquery], pixel_size)
      break
    endif

    if n_elements(wordsquery) gt 0 then begin
      variations = (n_elements(dict) / 2 - n_elements(wordsquery)) / n_elements(wordsquery)

      ; add random variations of used words
      dict = [dict[wordsquery], vis_cs_gaussdict_createvariation(dict[wordsquery], W, H, MinSigma, MaxSigma, MaxAnisotropy, variations, pixel_size, RANDOMU(seed + 1, 1))]

      ;fill up dictionary to match original number of words
      dict = [dict, vis_cs_gaussdict_create(W, H, MinSigma, MaxSigma, MaxAnisotropy, Elements - n_elements(dict), pixel_size, RANDOMU(seed + 2, 1))]
    endif else begin
      break
    endelse

  endfor

  return, {res: res, version: version}
end