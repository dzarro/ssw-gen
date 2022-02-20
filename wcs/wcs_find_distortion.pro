;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_DISTORTION
;
; Purpose     :	Find distortion information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure extracts distortion information from a FITS
;               index structure, and adds it to a World Coordinate System
;               structure in a separate DISTORTION substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_TIME, INDEX, TAGS, SYSTEM, WCS
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	INDEX  = Index structure from FITSHEAD2STRUCT.
;               TAGS   = The tag names of INDEX
;               SYSTEM = A one letter code "A" to "Z", or the null string
;                        (see wcs_find_system.pro).
;               WCS    = A WCS structure, from FITSHEAD2WCS.
;
; Opt. Inputs :	None.
;
; Outputs     : The output is the structure DISTORTION, which will contain one
;               or more of the following parameters, depending on the contents
;               of the FITS header:
;
;                       DPi (i=1,2,...)         prior distortion
;                       DQi (i=1,2,...)         subsequent distortion
;                       DVERR                   Maximum of all distortions
;
;               The DPi and DQi parameters are themselves structures with the
;               following parameters:
;
;                       PARAM   Array of distortion parameter names
;                       VALUE   Array of distortion parameter values
;                       CDIS    Distortion function type
;                       CERR    Array of maximum distortions per axis
;
; Opt. Outputs:	None.
;
; Keywords    :	COLUMN    = String containing binary table column number, or
;                           the null string.
;
;               LUNFXB    = The logical unit number returned by FXBOPEN,
;                           pointing to the binary table that the header
;                           refers to.  Usage of this keyword allows
;                           implementation of the "Greenbank Convention",
;                           where keywords can be replaced with columns of
;                           the same name.
;
;               ROWFXB    = Used in conjunction with LUNFXB, to give the
;                           row number in the table.  Default is 1.
;
; Calls       :	DELVARX, WCS_FIND_KEYWORD, DATATYPE, ADD_TAG
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
pro wcs_find_distortion, index, tags, system, wcs, column=column, $
                         lunfxb=lunfxb, rowfxb=rowfxb
on_error, 2
if n_elements(column) eq 0 then column=''
;
;  Determine the number of axes that can potentially have distortion parameters
;  associated with them.
;
naxes = n_elements(wcs.naxis)
;
;  For each axis, look for the following keywords and values.
;
;       CPDISj  Prior distortion function type
;       CQDISi  Subsequent distortion function type
;       DPj     Prior distortion parameter
;       DQj     Subsequent distortion parameter
;       CPERRj  Maximum prior correction for axis j
;       CQERRj  Maximum subsequent correction for axis j
;
delvarx, distortion
for iaxis = 1,naxes do begin
    delvarx, dp, dq
;
;  First look for the DPj keywords.
;
    str = wcs_find_keyword(index, tags, column, system, count, $
                           'DP'+ntrim(iaxis), ntrim(iaxis)+'DP', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  Parse the keywords.
;
        nstr = n_elements(str)
        param = strarr(nstr)
        value = param
        for i=0,nstr-1 do begin
            len = strlen(str[i])
            colon = strpos(str[i], ':')
            if colon lt 1 then begin
                message, /continue, 'Malformed distortion keyword ' + str
                return
            endif
            param[i] = strmid(str[i], 0, colon)
            value[i] = strtrim(strmid(str[i], colon+1, len-colon-1), 2)
        endfor
;
;  Get the additional keywords.
;
        name = 'CPDIS' + ntrim(iaxis)
        cpdis = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if datatype(cpdis) ne 'STR' then cpdis = 'Polynomial'
        dp = {param: param, value: value, cdis: cpdis}
;
        name = 'CPERR' + ntrim(iaxis)
        cperr = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if count gt 0 then dp = add_tag(dp, cperr, 'cerr')
;
;  Add the distortion description.
;
        distortion = add_tag(distortion, dp, 'DP' + ntrim(iaxis))
    endif
;
;  Next, look for the DQi keywords.
;
    str = wcs_find_keyword(index, tags, column, system, count, $
                           'DQ'+ntrim(iaxis), ntrim(iaxis)+'DQ', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  Parse the keywords.
;
        nstr = n_elements(str)
        param = strarr(nstr)
        value = param
        for i=0,nstr-1 do begin
            len = strlen(str[i])
            colon = strpos(str[i], ':')
            if colon lt 1 then begin
                message, /continue, 'Malformed distortion keyword ' + str
                return
            endif
            param[i] = strmid(str[i], 0, colon)
            value[i] = strtrim(strmid(str[i], colon+1, len-colon-1), 2)
        endfor
;
;  Get the additional keywords.
;
        name = 'CQDIS' + ntrim(iaxis)
        cqdis = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if datatype(cqdis) ne 'STR' then cqdis = 'Polynomial'
        dq = {param: param, value: value, cdis: cqdis}
;
        name = 'CQERR' + ntrim(iaxis)
        cqerr = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if count gt 0 then dq = add_tag(dq, cqerr, 'cerr')
;
;  Add the distortion description.
;
        distortion = add_tag(distortion, dq, 'DQ' + ntrim(iaxis))
    endif
endfor
;
;  If any distortion parameters were found, then also look for the DVERR
;  keyword.
;
if n_elements(distortion) gt 0 then begin
    dverr = wcs_find_keyword(index, tags, column, system, count, $
                             'DVERR', 'DVERR', lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then $
      distortion = add_tag(distortion, dverr, 'dverr', /top_level)
;
;  Add the DISTORTION tag to the WCS structure.
;
    if tag_exist(wcs, 'DISTORTION', /top_level) then $
      wcs = rem_tag(wcs, 'DISTORTION')
    wcs = add_tag(wcs, distortion, 'DISTORTION', /top_level)
endif
;
return
end
