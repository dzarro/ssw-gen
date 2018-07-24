;+
; Name: sff_search
;
; Purpose: Searches the SFF_LIST.TXT file for solar flares with chosen
; properties selected in the SOLAR_FLARE_FINDER.PRO widget
;
; x0 = SOL number
; x1 = GOES start
; x2 = GOES peak
; x3 = GOES end
; x4 = GOES class
; x5 = AIA X-position
; x6 = AIA y-position
; x7 = RHESSI number
; x8 = RHESSI percentage coverage of rise phase
; x9 = RHESSI High Energy[ 0 ]
; x10 = RHESSI High Energy[ 1 ]
; x11 = RHESSI X-position
; x12 = RHESSI Y-position
; x13 = RHESSI
; x14 = SDO/EVE MEGS-A
; x15 = SDO/EVE MEGS-B
; x16 = Hinode/EIS
; x17 = Hinode/SOT
; x18 = Hinode/XRT
; x19 = IRIS
; x20 = filename
;
; Calling arguments: Called by SOLAR_FLARE_FINDER.PRO
;  
; Written: Ryan Milligan, 24-Jun-2016
; Modifications:
; 19-Sep-2017, Kim. Now sff list text file is already read in by main program, just pass it in in keyword
;   (and remove run_offline keyword)
; 02-Feb-2018, Kim. Change index in search of AIA location from 11 to 5.
;-
function sff_search, timerange, class, hen, loc, cov, hin, sdo, iris, sff_list=sff_list

  index = [ class, hen, loc, cov, hin, sdo, iris ]
  flags = total( index[ 4:9 ] )+4.

  ;; Search within the chosen timerange first
  flare_list_ind = where( anytim( sff_list[ 1, * ] ) ge anytim( timerange[ 0 ] ) and anytim( sff_list[ 3, * ] ) ge anytim( timerange[ 0 ] ) and $
                                         anytim( sff_list[ 1, * ] ) le anytim( timerange[ 1 ] ) and anytim( sff_list[ 3, * ] ) le anytim( timerange[ 1 ] ) )
  flare_list = sff_list[ *, flare_list_ind ]

;; Exclusive flags  
  if ( class eq 0 ) then goes_ind = where( reform( strmid( flare_list[ 4, * ], 0, 1 ) eq 'B' ) )
  if ( class eq 1 ) then goes_ind = where( reform( strmid( flare_list[ 4, * ], 0, 1 ) eq 'C' ) )
  if ( class eq 2 ) then goes_ind = where( reform( strmid( flare_list[ 4, * ], 0, 1 ) eq 'M' ) )
  if ( class eq 3 ) then goes_ind = where( reform( strmid( flare_list[ 4, * ], 0, 1 ) eq 'X' ) )
  if ( class eq 4 ) then goes_ind = indgen( n_elements( flare_list[ 4, * ] ) )

  if ( hen eq 0 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 6. )
  if ( hen eq 1 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 12. )
  if ( hen eq 2 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 25. )
  if ( hen eq 3 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 50. )
  if ( hen eq 4 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 100. )
  if ( hen eq 5 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 300. )
  if ( hen eq 6 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 800. )
  if ( hen eq 7 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 7000. )
  if ( hen eq 8 ) then hsi_ind = where( str2number( flare_list[ 10, * ] ) eq 20000. )
  if ( hen eq 9 ) then hsi_ind = indgen( n_elements( flare_list[ 10, * ] ) )

;; RHESSI locations  
  ;if ( loc eq 0 ) then loc_ind = where( ( str2number( flare_list[ 11, * ] ) ge -600. ) and ( str2number( flare_list[ 11, * ] ) le 600. ) )
  ;if ( loc eq 1 ) then loc_ind = where( ( str2number( flare_list[ 11, * ] ) le -600. ) or ( str2number( flare_list[ 11, * ] ) ge 600. ) )
  ;if ( loc eq 2 ) then loc_ind = indgen( n_elements( flare_list[ 11, * ] ) )

;; AIA locations
  if ( loc eq 0 ) then loc_ind = where( ( str2number( flare_list[ 5, * ] ) ge -600. ) and ( str2number( flare_list[ 5, * ] ) le 600. ) )
  if ( loc eq 1 ) then loc_ind = where( ( str2number( flare_list[ 5, * ] ) le -600. ) or ( str2number( flare_list[ 5, * ] ) ge 600. ) )
  if ( loc eq 2 ) then loc_ind = indgen( n_elements( flare_list[ 5, * ] ) )

  if ( cov eq 0 ) then cov_ind = where( str2number( flare_list[ 8, * ] ) ge 0. and ( str2number( flare_list[ 8, * ] ) le 100. ) )
  if ( cov eq 1 ) then cov_ind = where( str2number( flare_list[ 8, * ] ) ge 90. and ( str2number( flare_list[ 8, * ] ) le 100. ) )
  if ( cov eq 2 ) then cov_ind = indgen( n_elements( flare_list[ 8, * ] ) )
     
;; Non-exclusive flags
  if ( sdo[ 0 ] eq 1 ) then ma_ind = where( flare_list[ 14, * ] eq '1' ) else ma_ind = -1       
  if ( sdo[ 1 ] eq 1 ) then mb_ind = where( flare_list[ 15, * ] eq '1' ) else mb_ind = -1
       
  if ( hin[ 0 ] eq 1 ) then eis_ind = where( flare_list[ 16, * ] eq '1' ) else eis_ind = -1
  if ( hin[ 1 ] eq 1 ) then sot_ind = where( flare_list[ 17, * ] eq '1' ) else sot_ind = -1
  if ( hin[ 2 ] eq 1 ) then xrt_ind = where( flare_list[ 18, * ] eq '1' ) else xrt_ind = -1

  if ( iris eq 1 ) then iris_ind = where( flare_list[ 19, * ] eq '1' ) else iris_ind = -1

;; Really smart way of looking for the common indices in each search pattern  
  dummy = [ goes_ind, hsi_ind, loc_ind, cov_ind, ma_ind, mb_ind, eis_ind, sot_ind, xrt_ind, iris_ind ]
  pos_int = where( dummy ne -1 )
  dummy2 = dummy[ pos_int ]
  order = sort( dummy2 )
  array = dummy2[ order ]
  find_changes, array, ind, st, index2d=i2
  q = where( ( i2[ 1, * ]-i2[ 0, * ] + 1 ) eq flags )

  ;if ( flags ne 0 ) then begin 
  if ( q[ 0 ] ne -1 ) then begin
    flare_index = reform( array[ i2[ 0, q ] ] )
    flares_found = reform( flare_list[ 20, flare_index ] )
  endif else flares_found = -1 ;reform( flare_list[ 17, * ] )
  ;endif else flares_found =  -1

  return, flares_found
  
end
