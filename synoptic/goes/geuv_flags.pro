;+
; Name: geuv_flags
; 
; Purpose: Modify geuv flags for eclipses, offpoints, and calibrations. There are messy data on either side of these 
;  conditions that the flags don't indicate, so expand flags to cover bad data.
; 
; Explanation: Called by geuv_read_files in the goes object when euv data is selected.
;  These are the modifications that are made to the flags read from the raw data files:
;  
;    Expand eclipse flags to include partial eclipse periods. 
;    If eclipse duration is >= 30 minutes, expand by 8 min before, 5 min after, 
;    If eclipse duration is < 30 minutes,  expand by 12 min before, 10 min after
;    (This is what GOES team does for 1-min averages as specified in
;    http://www.ngdc.noaa.gov/stp/satellite/goes/doc/GOES_NOP_EUV_readme.pdf)
;
;    Expand offpoint flags by 1 minute on either side since there are usually a few low points just before or after offpoint
;    
;    Expand calibration flags by 5 minutes on either side since messed up points extend about that far.
; 
;    NOT DONE: Could also try to set a bad data flag for +-4 hours of local midnight to remove data that has 
;    absorption dips near midnight due to geocoronal hydrogen absorption. Janet Machol gave me instructions 
;    (in an email 4/6/2016) on how to generate a file containing local midnight info using http://sscweb.gsfc.nasa.gov/, but 
;    perhaps we don't want to eliminate these data.
;
; Input Arguments:
;  tarray - time array corresponding to flags array (in sec since 1/1/1979)
;  flags - flags indicating conditions in data (described in Table 2 in 
;          http://www.ngdc.noaa.gov/stp/satellite/goes/doc/GOES_NOP_EUV_readme.pdf )
;          
; Output Argument:
;  flags input argument is changed to contain the expanded flags
;             
; Written: 3/1/2016, Kim Tolbert
; Modifications:
;
;-

;-----------------
; geuv_flags_expand is called by geuv_flags to identify the elements to change, and to make that change
; 
; Arguments:
;  tarray, flags - same as input to geuv_flags
;  bad_flags - values of flags to locate
;  bad_expand - either [2] or [2,2] - number of seconds before and after 'bad_flags' was found to set with new_flag,
;               must be [2,2] if thresh is set, 
;  new_flag - value to set in the expanded flag indices
;  thresh - threshold number of seconds for duration of bad_flags value - if < thresh, use bad_expand[*,0]
;           if duration > thresh, use bad_expand[*,1]
;          
; Returns modified flags array

pro geuv_flags_expand, tarray, flags, bad_flags, bad_expand, new_flag, thresh=thresh

qbad = where(is_member(flags, bad_flags), kbad)
tbad = tarray[qbad]
ntotelem = n_elements(flags)

if kbad gt 0 then begin
  z = find_contig(qbad, dum, ss)
  nsets = n_elements(ss) eq 2 ? 1 : n_elements(ss[*,0])
  for ii=0,nsets-1 do begin
    s0 = nsets eq 1 ? ss[0] : ss[ii,0]
    s1 = nsets eq 1 ? ss[1] : ss[ii,1]
    
    sec_expand = bad_expand[0:1]    
    if n_elements(bad_expand) eq 4 and keyword_set(thresh) then begin
      if (tbad[s1] - tbad[s0]) ge thresh then sec_expand = bad_expand[2:3]
    endif
    
    q0 = where(tarray gt (tbad[s0] - sec_expand[0]))
    q1 = where(tarray lt (tbad[s1] + sec_expand[1]))
    flags[q0[0]:last_item(q1)] = new_flag
  endfor
  
endif
end

;-----------------

pro geuv_flags, tarray, flags

; all eclipse flags (earth,moon, combination,etc)
eclipse_flags = [4194304, 8388608, 12582912, 14680064]
eclipse_expand1 = 60. * [8.,  5.] ; for > 30 min duration of eclipse
eclipse_expand2 = 60. * [12., 10.] ; for < 30 min duration of eclipse
new_flag = 5

offpoint_flags = 2097152
offpoint_expand = 60. * [1., 1.]
new_flag = 8

calib_flags = [1048576, 3145728]
calib_expand = 60. * [5., 5.]
new_flag = 8

geuv_flags_expand, tarray, flags, eclipse_flags, [eclipse_expand1,eclipse_expand2], new_flag, thresh=1800
geuv_flags_expand, tarray, flags, offpoint_flags, offpoint_expand, new_flag
geuv_flags_expand, tarray, flags, calib_flags, calib_expand, new_flag

end