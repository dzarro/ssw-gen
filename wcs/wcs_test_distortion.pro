;+
; Project     :	Solar Orbiter
;
; Name        :	WCS_TEST_DISTORTION
;
; Purpose     :	Test for distortion parameter keywords.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure examines the name of a FITS keyword to determine
;               whether it fits the pattern of a WCS distortion parameter
;               keyword.  Such keywords take multiple values.  Possible keyword
;               forms are:
;
;                       DPja    Parameter for a prior distortion function
;                       DQia    Parameter for a subsequent distortion function
;                       jDPna   Binary table form of DPja
;                       iDQna   Binary table form of DQia
;                       TDPna   Pixel list form of DPja
;                       TDQna   Pixel list form of DQia
;
; Syntax      :	Result = WCS_TEST_DISTORTION( keyword )
;
; Examples    :	See FITSHEAD2STRUCT
;
; Inputs      :	KEY     = Keyword to test
;
; Opt. Inputs :	None.
;
; Outputs     :	The result of the function is 0 or 1, depending on whether the
;               keyword matches one of the allowed forms.
;
; Opt. Outputs:	None.
;
; Keywords    :	None.
;
; Calls       :	VALID_NUM
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 6-Jun-2019, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
function wcs_test_distortion, key
;
;  Look for the letter combinations DP or DQ.
;
testkey = strupcase(key)
i0 = strpos(testkey, 'DP') > strpos(testkey, 'DQ')
if i0 lt 0 then return, 0
;
;  If there's anything before the DP/DQ, make sure that it's either a number or
;  the letter T
;
if i0 gt 0 then begin
    prefix = strmid(testkey,0,i0)
    if (prefix ne 'T') and (not valid_num(prefix)) then return, 0
endif
;
;  Make sure there's something after the DP/DQ.
;
len = strlen(testkey)
if len le (i0+2) then return, 0
;
;  Test if the part after the DP/DQ is a number.
;
suffix = strmid(testkey, i0+2, len-i0-2)
if not valid_num(suffix) then begin
;
;  If it's not a number, make sure that it has more than one character.
;
    slen = strlen(suffix)
    if slen eq 1 then return, 0
;
;  Split off the last character from the suffix, and see if the remainder is a
;  number.  Also check that the last character is a letter from A to Z.
;
    testnum = strmid(suffix,0,slen-1)
    char = byte(strmid(suffix,slen-1,1))
    if (not valid_num(testnum)) or (char lt 65) or (char gt 90) then $
      return, 0
endif
;
;  If we go this far, it's a proper distortion parameter keyword.
;
return, 1
end
