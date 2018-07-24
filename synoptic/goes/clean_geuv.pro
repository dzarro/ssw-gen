;+
; Project     :  SDAC
;
; Name        :  CLEAN_GEUV
;
; Purpose     :  This procedure finds bad data points and flags them.
;
; Category    :  GOES
;
; Explanation :  CLEAN_GEUV finds bad data points (flag in stat is non-zero, or yarray[*,0] value is <=0), 
;                and sets them to -99999 in the yclean array (which is otherwise equal to the yarray array). 
;                Also sets bad0 and bad1, the indices into yclean[*,0] and yclean[*,1] that are bad.
;                When plotting, if clean option is selected, we'll remove the points where yclean is -99999.
;                
;                Note: with GOES XRS data, the second channel is the low channel.  For EUV only channel 0 
;                is used, except for EUVE, where channel 0 contains the 'corrected' (for degradation and 
;                scaled to SOLSTICE) EUVE data, and channel 1 contains the uncorrected data.
;
;
; Use         : clean_geuv, goes, tarray = tarray, yarray = yarray, yclean = yclean, $
;               bad0 = bad0, bad1 = bad1, numstat=numstat, tstat=tstat, stat=stat, error=error
;
; Optional Input: GOES - structure obtained from RD_GXD with tags time, day, lo, and hi (if used, then
;                   tarray and yarray keywords are ignored.)
;
; Input Keywords: 
;        TARRAY- time in utime format, sec from 1-jan-1979, dblarr(nbins) corresponding to yarray
;        YARRAY- raw GOES EUV data, fltarr(nbins, 2)
;        NUMSTAT- Number of bad timesin TSTAT and bad flags in STAT. Default value is -1.
;        TSTAT - times of bad values
;        STAT - flag at tstat times
;        
; Output Keywords:
;        YCLEAN- cleaned YARRAY (same as yarray, with bad points set to -99999.)
;        BAD0 - indices of bad values in yclean[*,0]
;        BAD1 - indices of bad values in yclean[*,1]
;        ERROR - 0 means no error
;
; Written: 3/1/2016, Kim Tolbert
; Modifications:
;
;-
  
pro clean_geuv, goes, tarray = tarray, yarray = yarray, yclean = yclean, $
  bad0=bad0, bad1=bad1, numstat=numstat, tstat=tstat, stat=stat, error=error
    
if datatype(goes) eq 'STC' then begin
  tarray = anytim( /sec, goes)
  yarray = reform( [goes.lo,goes.hi],n_elements(tarray), 2)
endif

error = 0
yclean = yarray
checkvar, numstat, -1

bad0 = -1
bad1 = -1
count_stat = 0  

if numstat gt 0 then begin
  qbad = where(stat ne 0, kbad)
  ; Find elements in tarray corresponding to times in tstat array of bad points. Result is put into bad0 variable.
  if kbad gt 0 then match, tarray, tstat[qbad], bad0, count=count_stat

;  if count_stat gt 0 then begin
;    bad0a = value_locate(tarray, tstat[qbad])
;    print,' match and value_locate return same? = ', same_data(bad0, bad0a)
;    if ~same_data(bad0, bad0a) then stop
;  end
endif

; Also find indices where y values are <=0.
more_bad = where(yarray[*,0] le 0., count_more)
;if count_more gt 0 then bad0 = count_stat gt 0 ? get_uniq([bad0,more_bad]) : more_bad

; Merge bad0 with more_bad
case 1 of
  count_stat gt 0 and count_more gt 0: bad0 = get_uniq([bad0,more_bad])
  count_stat eq 0 and count_more gt 0: bad0 = more_bad
  else:
endcase

bad1 = bad0 ; same flags for second index

if bad0[0] ne -1 then yclean[bad0,*] = -99999.

error = 0
end