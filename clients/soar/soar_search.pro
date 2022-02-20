;+
; Project     :	Solar Orbiter
;
; Name        :	SOAR_SEARCH()
;
; Purpose     :	Search the Solar Orbiter Archive for file closest in time.
;
; Category    :	utility system sockets
;
; Explanation :	This routine searches the Solar Orbiter Archive for a data file
;               for a given instrument closest to a specified date and time.
;
; Syntax      :	Result = SOAR_SEARCH(date, instrument)
;
; Examples    :	Result = SOAR_SEARCH('2020-05-30 12:00', 'EUI')
;               Result = SOAR_SEARCH('2020-05-30 12:00', 'EUI', $
;                               PROCESSING_LEVEL=1, SEARCH='HRI')
;
; Inputs      :	DATE = Date/time value, in a format supported by the routine
;                      ANYTIM2UTC.
;
;               INSTRUMENT = Instrument acronym.
;
; Opt. Inputs :	None
;
; Outputs     :	The result of the function is a structure with the following
;               tags:
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
;               VERSION = File version to request, either as a number or a
;                         character string, e.g. VERSION="V03".  The default is
;                         to return the highest version.
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
;               MAX_SECONDS = Maximum number of seconds to search around the
;                             specified time.  Default is one day.
;
;               MAX_MINUTES = Maximum number of minutes for search.  Supercedes
;                             MAX_SECONDS.
;
;               MAX_HOURS   = Maximum number of hours for search.  Supercedes
;                             MAX_MINUTES and MAX_SECONDS.
;
;               MAX_DAYS    = Maximum number of days for search.  Supercedes
;                             MAX_SECONDS, MAX_MINUTES, and MAX_HOURS.
;
;               VERBOSE   = If set, then print out additional information.
;
;               ERRMSG    = If defined and passed, then any error messages 
;                           will be returned to the user in this parameter 
;                           rather than being printed to the screen.  If no
;                           errors are encountered, then a null string is
;                           returned.  In order to use this feature, the 
;                           string ERRMSG must be defined first, e.g.,
;
;                                ERRMSG = ''
;                                Result = SOAR_SEARCH( ERRMSG=ERRMSG, ...)
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
;               Version 3, 07-Oct-2021, WTT, add keyword VERSION, return
;                       highest version by default
;
; Contact     :	WTHOMPSON
;-
;
function soar_search, date, v_instrument, low_latency=low_latency, $
                      processing_level=processing_level, verbose=verbose, $
                      max_seconds=max_seconds, max_minutes=max_minutes, $
                      max_hours=max_hours, max_days=max_days, search=search, $
                      omit=omit, version=k_version, errmsg=errmsg
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
;  Define the maximum search time.
;
dtai_max = 86400.d0
if n_elements(max_seconds) eq 1 then dtai_max = abs(max_seconds)
if n_elements(max_minutes) eq 1 then dtai_max = abs(max_minutes) * 60.d0
if n_elements(max_hours)   eq 1 then dtai_max = abs(max_hours) * 3600.d0
if n_elements(max_days)    eq 1 then dtai_max = abs(max_days) * 86400.d0
;
if n_params() ne 2 then begin
    message = 'Syntax: Result = SOAR_SEARCH(date, instrument)'
    goto, handle_error
endif
;
message = ''
tai0 = anytim2tai(date, errmsg=message)
if message ne '' then goto, handle_error
;
;  Start with a search time of one hour, up to the maximum.
;
dtai = 3600.d0 < dtai_max
;
iterate:
tai1 = tai0 - dtai  &  utc1 = tai2utc(tai1, /ccsds)
tai2 = tai0 + dtai  &  utc2 = tai2utc(tai2, /ccsds)
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
;  If no entries were found, the header will consist of a single ''.  Try
;  increasing the search period by a factor of 10, up to the maximum.
;
if n_elements(header) eq 1 then begin
expand_search:
    if dtai ge dtai_max then begin
        message = 'No files found'
        goto, handle_error
    endif
    dtai = (10 * dtai) < dtai_max
    goto, iterate
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
    if count eq 0 then goto, expand_search
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
    if count eq 0 then goto, expand_search
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
;  Find the entry closest to the requested time.  Select the highest version
;  number.
;
tai = utc2tai(begin_time)
delta = abs(tai - tai0)
w = where(delta eq min(delta))
if n_elements(k_version) eq 0 then version = max(item_version[w]) else begin
    if datatype(k_version) eq 'STR' then version = k_version else $
      version = 'V' + string(round(k_version), format='(I2.2)')
endelse
w = w[where(item_version[w] eq max(item_version[w]))]
result = {archived_on: archived_on[w[0]], $
          begin_time: begin_time[w[0]], $
          data_type: data_type[w[0]], $
          file_name: file_name[w[0]], $
          file_size: file_size[w[0]], $
          instrument: instrument[w[0]], $
          item_id: item_id[w[0]], $
          item_version: item_version[w[0]], $
          processing_level: processing_level[w[0]]}

return, result
;
handle_error:
if n_elements(errmsg) ne 0 then errmsg = message else $
  message, message, /continue
return, -1
;
end
