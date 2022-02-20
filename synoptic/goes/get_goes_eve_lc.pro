;+
;NAME: get_goes_eve_lc
;
;PURPOSE : Accumulate either GOES or EVE GOES Proxy data for requested time interval. Tries GOES first,
; if not, tries EVE.
;
;Calling arguments:
; time_range - start/end of time interval in anytim format
;
;Input Keywords:
; plot - if set, plot
;
;Output Keywords:
; type - 'GOESxx' or 'EVE' indicating which type of data was accumulated
; res - resolution for data (GOES only), e.g. '1 sec'
; arch - name of archive data came from (GOES only), e.g. 'NOAA' or 'SDAC' or 'YOHKOH'
; 
;Output:
; returns a structure with time, lo, hi
; 
;EXAMPLE : 
;   data = get_goes_eve_lc(['2003/03/02 00:00','2003/03/03 00:00'])
;   
;WRITTEN : Steven Christe (15-Jan-2011)
;MODIFIED : Kim Tolbert, 7-May-2012.  Renamed and put online in ssw
;
; 04-jun-2020, Kim. Added res and arch keywords, and added /quiet to goes getdata call
;
;-

FUNCTION get_goes_eve_lc, time_range, type=type, res=data_res, arch=arch_name

result = -1
type = ''

tr = anytim(time_range, /vms)

goes_obj = ogoes()
goes_obj->set, /noaa

goes_obj -> set, tstart = tr[0], tend = tr[1]
lo = goes_obj -> getdata(/low, /quiet)
hi = goes_obj -> getdata(/high, /quiet)

if lo[0] ne -1 then begin
    result = create_struct('time', 0.d, 'lo', 0.0, 'hi', 0.0, 'name', '')
    result = replicate(result, n_elements(lo))
    
    result.time = goes_obj -> getdata(/times) + anytim(goes_obj->get(/utbase))
    result.lo = lo
    result.hi = hi    
    type = goes_obj->get(/sat)
    data_res = goes_obj->get_res(/string)
    arch_name = goes_obj->get_arch_name()
    
endif else begin    

    eve_obj = obj_new('eve_goes', tstart=tr[0], tend=tr[1])
    result = eve_obj -> getdata()
    if is_struct(result) then begin
      ; convert the times, which are sec since 1/1/1958, to sec since 1/1/1979
      result.time = anytim( tai2utc(result.time) )
      type='EVE'
      data_res = ''
      arch_name = ''
    endif
    obj_destroy, eve_obj

endelse

obj_destroy, goes_obj

RETURN, result

END
