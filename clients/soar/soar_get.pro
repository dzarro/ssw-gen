;+
; Project     :	Solar Orbiter
;
; Name        :	SOAR_GET()
;
; Purpose     :	Copy a file from the Solar Orbiter Archive.
;
; Category    :	utility system sockets
;
; Explanation : This routine copies over a file from the Solar Orbiter Archive
;               based on the output of SOAR_SEARCH or SOAR_LIST.  If the file
;               already exists, and has the proper size, then the routine will
;               immediately return success.
;
; Syntax      :	Result = SOAR_GET(DESC)
;
; Examples    :	DESC = SOAR_SEARCH('2020-05-30 12:00', 'EUI')
;               Result = SOAR_GET(DESC)
;
; Inputs      : DESC = Structure (from SOAR_SEARCH or SOAR_LIST) containing a
;                      description of the file to be copied over.  At a bare
;                      minimum, must contain the following tags:
;
;                       DATA_TYPE
;                       FILE_NAME
;                       FILE_SIZE
;                       ITEM_ID
;
;               If DESC is an array, then the routine is called in a loop until
;               completed, or an error is reached.
;
; Opt. Inputs :	None
;
; Outputs     :	The result of the function is 1 if successful, or 0 if not
;               successful.  If DESC is an array, then the result will also be
;               an array.
;
; Opt. Outputs:	None
;
; Keywords    :	OUT_DIR = Optional output directory to write file to.
;
;               VERBOSE = If set, then print out additional information.
;
;               ERRMSG    = If defined and passed, then any error messages 
;                           will be returned to the user in this parameter 
;                           rather than being printed to the screen.  If no
;                           errors are encountered, then a null string is
;                           returned.  In order to use this feature, the 
;                           string ERRMSG must be defined first, e.g.,
;
;                                ERRMSG = ''
;                                Result = SOAR_GET( ERRMSG=ERRMSG, ...)
;                                IF ERRMSG NE '' THEN ...
;
; Calls       :	DATATYPE, TAG_EXIST, MK_DIR, FILE_EXIST, SOCK_GET
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 11-Jan-2021, William Thompson, GSFC
;               Version 2, 13-Jan-2021, WTT, change to use SOCK_GET
;
; Contact     :	WTHOMPSON
;-
;
function soar_get, desc, out_dir=out_dir, verbose=verbose, errmsg=errmsg
;
on_error, 2
;
;  Check that DESC has the proper structure, and extract the needed
;  information.
;
if (datatype(desc) ne 'STC') then begin
    message = 'DESC must be a structure'
    goto, handle_error
endif
;
n = n_elements(desc)
result = bytarr(n)
if n gt 1 then begin
    for i=0,n-1 do begin
        message = ''
        result[i] = soar_get(desc[i], out_dir=out_dir, verbose=verbose, $
                             errmsg=message)
        if message ne '' then goto, handle_error
    endfor
    return, result
endif
;
if tag_exist(desc, 'FILE_NAME') then filename = desc.file_name else begin
    message = 'FILE_NAME not found in structure'
    goto, handle_error
endelse
;
if tag_exist(desc, 'FILE_SIZE') then file_size = desc.file_size else begin
    message = 'FILE_SIZE not found in structure'
    goto, handle_error
endelse
;
if tag_exist(desc, 'ITEM_ID') then item_id = desc.item_id else begin
    message = 'ITEM_ID not found in structure'
    goto, handle_error
endelse
;
;  Use DATA_TYPE to determine whether this is a science or low latency file.
;
if tag_exist(desc, 'DATA_TYPE') then begin
    type = desc.data_type
    if type eq 'LL' then type = "LOW_LATENCY" else type = "SCIENCE"
end else begin
    message = 'DATA_TYPE not found in structure'
    goto, handle_error
endelse
;
cd, current=current
if n_elements(out_dir) eq 0 then out_dir = current
if not dir_exist(out_dir) then begin
    mk_dir, out_dir, err=message
    if message ne '' then goto, handle_error
endif
;
;  Check to see if the file already exists.  If it does exist, check to see
;  that it has the proper size.
;
cd, out_dir
if file_exist(filename) then begin
    fsize = (file_info(filename)).size
    if fsize eq file_size then return, 1b else file_delete, filename
endif
;
;  Form the URL, and copy over the file.
;
url = "http://soar.esac.esa.int/soar-sl-tap/data?retrieval_type=" + $
      "LAST_PRODUCT&product_type=" + type + "&data_item_id=" + item_id
if keyword_set(verbose) then print, url
sock_get, url
result = file_exist(filename)
if result then begin
    fsize = (file_info(filename)).size
    if fsize ne file_size then begin
        message = 'Incomplete file copy'
        goto, handle_error
    endif
endif
cd, current
return, result
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) ne 0 then errmsg = message else $
  message, message, /continue
return, result
;
end
