;+
; Project     :	Solar Orbiter
;
; Name        :	SOAR_LIST()
;
; Purpose     :	Search the Solar Orbiter Archive for files in time range
;
; Category    :	utility system sockets
;
; Explanation :	This routine searches the Solar Orbiter Archive for data files
;               covering a given day or time range.
;
; Syntax      :	Result = SOAR_LIST(date, instrument)
;
; Examples    :	Result = SOAR_LIST('2020-05-30', 'EUI')
;               Result = SOAR_LIST(['2020-05-30T12', '2020-05-30T14'], 'EUI')
;               Result = SOAR_LIST('2020-05-30', 'EUI', PROCESSING_LEVEL=1)
;               Result = SOAR_LIST('2020-05-30', 'EUI', SEARCH='HRI')
;
; Inputs      :	DATE = Either a date to search, or a two-element array giving
;                      the start and stop time to search.
;
;               INSTRUMENT = Instrument acronym.
;
; Opt. Inputs :	None
;
; Outputs     : The result of the function is a structure array with the
;               following tags:
;
;                       ARCHIVED_ON
;                       BEGIN_TIME
;                       DATA_TYPE
;                       FILE_NAME
;                       FILE_SIZE
;                       INSTRUMENT
;                       ITEM_ID
;                       ITEM_VERSION
;                       PROCESSING_LEVEL
;
; Opt. Outputs:	None
;
; Keywords    :	LOW_LATENCY = If set, then search the low latency files.  The
;                             default is to search the science files.
;
;               PROCESSING_LEVEL = Processing level to search, default is 2.
;
;               SEARCH = String array containing terms to search for within the
;                        filename, e.g. SEARCH='fsi174'.  It's not
;                        recommended to use purely numerical search parameters
;                        as they may also appear in the date/time parts of the
;                        filename.  When multiple search terms are
;                        passed, they're treated as being connected by AND.
;
;               OMIT   = String array containing terms which should not appear
;                        in the filename.
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
;                                Result = SOAR_LIST( ERRMSG=ERRMSG, ...)
;                                IF ERRMSG NE '' THEN ...
;
; Calls       :	ANYTIM2TAI, TAI2UTC, SOCK_GET, READ_CSV, UTC2TAI, FILE_EXIST
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
;               Version 2, 12-Jan-2021, WTT, added SEARCH, OMIT keywords.
;               Version 3, 08-Jul-2021, WTT, corrected documentation
;               Version 4, 09-Nov-2021, WTT, return only highest version number
;
; Contact     :	WTHOMPSON
;-
;
function soar_list, date, v_instrument, low_latency=low_latency, $
                      processing_level=processing_level, verbose=verbose, $
                      search=search, omit=omit, errmsg=errmsg
;
on_error, 2
;
if n_elements(processing_level) eq 1 then level=processing_level else level=2
if keyword_set(low_latency) then begin
    type = "LL"
    level = "LL" + string(level,format='(I2.2)')
end else begin
    type = "SCI"
    level = "L" + string(level,format='(I1)')
endelse
;
;  Define the search range.
;
message = ''
utc = anytim2utc(date, errmsg=message)
if message ne '' then goto, handle_error
if n_elements(utc) eq 1 then begin
    utc.time = 0
    utc = replicate(utc,2)
    utc[1].mjd = utc[0].mjd + 1
end else if n_elements(utc) ne 2 then begin
    message = 'Date must have one or two values'
    goto, handle_error
endif
utc1 = utc2str(utc[0])
utc2 = utc2str(utc[1])
;
;  Form the URL for the search.
;
url = "http://soar.esac.esa.int/soar-sl-tap/tap/sync?" + $
      "REQUEST=doQuery&LANG=ADQL&FORMAT=csv&QUERY=SELECT * " + $
      "FROM v_public_files WHERE data_type='" + type + "' " + $
      "AND instrument='" + ntrim(strupcase(v_instrument)) + "' " + $
      "AND processing_level='" + ntrim(level) + "' AND begin_time %3E= '" + $
      utc1 + "' AND begin_time %3C= '" + utc2 + "'"
if keyword_set(verbose) then print, url
;
sock_get, url, local_file=csv_file
if not file_exist(csv_file) then begin
    message = 'No CSV file returned'
    goto, handle_error
endif
table = read_csv(csv_file, header=header)
file_delete, csv_file
if n_elements(header) eq 0 then begin
    message = 'Unable to read CSV header'
    goto, handle_error
endif
;
;  If no entries were found, the header will consist of a single ''.
;
if n_elements(header) eq 1 then begin
    message = 'No files found'
    goto, handle_error
endif
;
;  Extract the information about the files
;
w = where(header eq 'archived_on')       &  archived_on = table.(w[0])
w = where(header eq 'begin_time')        &  begin_time = table.(w[0])
w = where(header eq 'data_type')         &  data_type = table.(w[0])
w = where(header eq 'file_name')         &  file_name = table.(w[0])
w = where(header eq 'file_size')         &  file_size = table.(w[0])
w = where(header eq 'instrument')        &  instrument = table.(w[0])
w = where(header eq 'item_id')           &  item_id = table.(w[0])
w = where(header eq 'item_version')      &  item_version = table.(w[0])
w = where(header eq 'processing_level')  &  processing_level = table.(w[0])
;
;  Apply any SEARCH terms.
;
for i=0,n_elements(search)-1 do begin
    s = strpos(strlowcase(file_name), strlowcase(ntrim(search[i])))
    w = where(s ge 0, count)
    if count eq 0 then begin
        message = 'No files found'
        goto, handle_error
    endif
    archived_on = archived_on[w]
    begin_time = begin_time[w]
    data_type = data_type[w]
    file_name = file_name[w]
    file_size = file_size[w]
    instrument = instrument[w]
    item_id = item_id[w]
    item_version = item_version[w]
    processing_level = processing_level[w]
endfor    
;
;  Apply any OMIT terms.
;
for i=0,n_elements(omit)-1 do begin
    s = strpos(strlowcase(file_name), strlowcase(ntrim(omit[i])))
    w = where(s lt 0, count)
    if count eq 0 then begin
        message = 'No files found'
        goto, handle_error
    endif
    archived_on = archived_on[w]
    begin_time = begin_time[w]
    data_type = data_type[w]
    file_name = file_name[w]
    file_size = file_size[w]
    instrument = instrument[w]
    item_id = item_id[w]
    item_version = item_version[w]
    processing_level = processing_level[w]
endfor    
;
result = {archived_on: archived_on[0], $
          begin_time: begin_time[0], $
          data_type: data_type[0], $
          file_name: file_name[0], $
          file_size: file_size[0], $
          instrument: instrument[0], $
          item_id: item_id[0], $
          item_version: item_version[0], $
          processing_level: processing_level[0]}
;
result = replicate(result,n_elements(archived_on))
result.archived_on      = archived_on
result.begin_time       = begin_time
result.data_type        = data_type
result.file_name        = file_name
result.file_size        = file_size
result.instrument       = instrument
result.item_id          = item_id
result.item_version     = item_version
result.processing_level = processing_level
;
;  Return only unique values for ITEM_ID.
;
u = uniq(result.item_id)
return, result[u]
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) ne 0 then errmsg = message else $
  message, message, /continue
return, -1
;
end
