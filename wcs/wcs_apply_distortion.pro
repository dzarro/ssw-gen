;+
; Project     :	STEREO
;
; Name        :	WCS_APPLY_DISTORTION
;
; Purpose     :	Apply distortion information in FITS header.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure is called from WCS_GET_COORD to apply the
;               distortion parameters in the DISTORTION substructure.  
;
; Syntax      :	WCS_APPLY_DISTORTION, WCS, PIX  [, /PRIOR ]
;
; Examples    :	See wcs_get_coord.pro
;
; Inputs      :	WCS = A WCS structure, from FITSHEAD2WCS.
;               PIX = An array of pixel values.  Unless the WCS structure
;                     defines a one-dimensional array, the first dimension
;                     of PIX must correspond to the number of dimensions in
;                     the FITS file.
;
; Opt. Inputs :	None.
;
; Outputs     : The input array PIX is returned with the distortion corrections
;               applied.
;
; Opt. Outputs:	None.
;
; Keywords    :	PRIOR = If set, then the prior distortion parameters are
;                       applied.  Otherwise, the subsequent distortion
;                       parameters are applied.
;
; Calls       :	
;
; Common      :	None.
;
; Restrictions:	The "Lookup" distortion type is not yet handled.
;
;               If any errors are found in the distortion keywords, then all
;               distortion keywords will be ignored.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 28-Jun-2019, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_apply_distortion, wcs, pix, prior=prior
;
;  Check the WCS structure.
;
if not valid_wcs(wcs) then begin
    message, /continue, 'A valid WCS structure was not passed.'
    return
endif
;
;  If there is no DISTORTION substructure, then simply return.
;
if not tag_exist(wcs, 'distortion') then return
;
;  Check the pixel array.  The first dimension must match the number of axes.
;
if n_elements(pix) eq 0 then begin
    message, /continue, 'No pixel array was passed.'
    return
endif
sz = size(pix)
ndim = n_elements(wcs.naxis)
if ndim gt 1 then $
  if (sz[0] eq 0) or (sz[1] ne ndim) then begin
    message, /continue, 'PIX array has wrong dimensions'
    return
endif
;
;  Rearrange the input array into two dimensions, and define the correction
;  array.  Keep track of the original dimensions.
;
if sz[0] eq 0 then dim0 = 0 else dim0 = sz[1:sz[0]]
dim = [ndim, n_elements(pix)/ndim]
pix = reform(pix, dim, /overwrite)
corr = make_array(dimension=dim, /double)
;  
;
;  Step through the axes, and look for distortion parameters for that axis.
;
for iaxis = 1,ndim do begin
    if keyword_set(prior) then tag = 'DP' else tag = 'DQ'
    tag = tag + ntrim(iaxis)
    if tag_exist(wcs.distortion, tag) then begin
        index = get_tag_index(wcs.distortion, tag)
        dist = wcs.distortion.(index)
        param = strupcase(dist.param)
        value = dist.value
;
;  Look for the function type.  If not defined, then the default is
;  "Polynomial".
;
        tag = 'CDIS'
        if tag_exist(dist, tag) then begin
            index = get_tag_index(dist, tag)
            dist_type = strupcase(dist.(index))
        end else dist_type = 'POLYNOMIAL'
;
;  Get the number of independent variables in the distortion function.
;
        w = where(param eq 'NAXES', count)
        if count eq 0 then begin
            message, /continue, 'No NAXES keyword found for dimension ' + $
                     ntrim(iaxis)
            goto, reform
        endif
        naxes = fix(value[w[0]])
;
;  Extract each independent variable.
;
        for jaxis = 1,naxes do begin
            par = 'AXIS.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count eq 0 then begin
                message = 'No AXIS keyword found for term ' + ntrim(jaxis) + $
                          ' along dimension ' + ntrim(iaxis)
                goto, handle_error
            endif
            kaxis = fix(value[w[0]])
            command = 'axis' + ntrim(jaxis) + '=pix[' + ntrim(kaxis-1) + ',*]'
            test = execute(command)
;
;  Apply the offset and scale, if any.
;
            par = 'OFFSET.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count gt 0 then begin
                offset = double(value[w[0]]) - 1 ;FITS->IDL notation
                test = execute('axis' + ntrim(jaxis) + '-=offset')
            endif
            par = 'SCALE.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count gt 0 then begin
                scale = double(value[w[0]])
                test = execute('axis' + ntrim(jaxis) + '*=scale')
            endif
        endfor
;
;  If the parameter NAUX exists, then calculate the auxiliary parameters.
;
        w = where(param eq 'NAUX', count)
        if count eq 0 then naux = 0 else begin
            naux = fix(value[w[0]])
            for iaux = 0,naux do begin
;
;  Get the zeroth coefficient, and initialize the auxiliary variable.
;
                par = 'AUX.' + ntrim(iaux) + '.COEFF.0'
                w = where(param eq par, count)
                if count eq 0 then term = 0 else term = double(value[w[0]])
                command = 'aux' + ntrim(iaux) + ' = term'
                test = execute(command)
;
;  For each axis, determine the power and coefficient of the axis, and apply it
;  the auxiliary variable.
;
                for jaxis = 1,naxes do begin
                    par = 'AUX.' + ntrim(iaux) + '.COEFF.' + ntrim(jaxis)
                    w = where(param eq par, count)
                    if count eq 0 then coeff = 0 else $
                      coeff = double(value[w[0]])
                    if coeff ne 0 then begin
                        command = 'aux' + ntrim(iaux) + ' += axis' + $
                                  ntrim(jaxis)
                        par = 'AUX.' + ntrim(iaux) + '.POWER.' + ntrim(jaxis)
                        w = where(param eq par, count)
                        if count ne 0 then begin
                            power = double(value[w[0]])
                            if power ne 1 then command = $
                              command + '^' + ntrim(power)
                        endif
                        test = execute(command)
                    endif
                endfor
;
;  Get the power for the expression as a whole, and apply it.
;
                par = 'AUX.' + ntrim(iaux) + 'POWER.0'
                w = where(param eq par, count)
                if count ne 0 then begin
                    power = double(value[w[0]])
                    command = 'aux' + ntrim(iaux) + ' = aux' +ntrim(iaux) + $
                              '^' + ntrim(power)
                endif
            endfor              ;IAUX
        endelse
;
;  Get the number of terms in the distortion function, and step through them.
;
        w = where(param eq 'NTERMS', count)
        if count eq 0 then begin
            message = 'No NTERMS keyword found for dimension ' + ntrim(iaxis)
            goto, handle_error
        endif
        nterms = fix(value[w[0]])
        for iterm = 1,nterms do begin
;
;  Get the coefficient.
;
            par = 'TERM.' + ntrim(iterm) + '.COEFF'
            w = where(param eq par, count)
            if count eq 0 then term = 1 else term = double(value[w[0]])
;
;  For each axis, determine the power of the axis, and apply it to the term.
;
            for jaxis = 1,naxes do begin
                par = 'TERM.' + ntrim(iterm) + '.VAR.' + ntrim(jaxis)
                w = where(param eq par, count)
                if count gt 0 then begin
                    power = double(value[w[0]])
                    if power ne 0 then begin
                        command = 'term *= axis' + ntrim(jaxis)
                        if power ne 1 then $
                          command = command + '^' + ntrim(power)
                        test = execute(command)
                    endif
                endif
            endfor
;
;  For each auxiliary variable, determ the power of the variable, and apply it
;  to the term.
;
            if naux gt 0 then for iaux = 1,naux do begin
                par = 'TERM.' + ntrim(iterm) + '.AUX.' + ntrim(iaux)
                w = where(param eq par, count)
                if count gt 0 then begin
                    power = double(value[w[0]])
                    if power ne 0 then begin
                        command = 'term *= aux' + ntrim(iaux)
                        if power ne 1 then $
                          command = command + '^' + ntrim(power)
                        test = execute(command)
                    endif
                endif
            endfor
;
;  Add the term to the correction.
;
            command = 'corr[' + ntrim(iaxis-1) + ',*] += term'
            test = execute(command)
        endfor                  ;Loop over ITERM
    endif                       ;Distortion parameters exist for IAXIS
endfor                          ;Loop over IAXIS
;
;  Apply the correction, and skip over the error handling part.
;
pix = pix + corr
goto, reform
;
handle_error:
if n_elements(errmsg) ne 0 then $
  errmsg = 'WCS_APPLY_DISTORTION: ' + message else $
  message, message, /continue
;
;  Restore the original dimensions, and return.
;
reform:
if dim0[0] eq 0 then pix = pix[0] else pix = reform(pix, dim0, /overwrite)
return
;
end
