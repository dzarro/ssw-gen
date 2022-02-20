;+
; Project     : VSO
;
; Name        : STR_SAME
;
; Purpose     : Return strings that the same in two arrays
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_same(input1,input2)
;
; Inputs      : INPUT1 = scalar or vector of strings to check
;             : INPUT2 = scalar or vector of strings to check
;
; Outputs     : OUTPUT = strings that are in INPUT1 and INPUT2
;
; Keywords    : COUNT = # of returned results
;               KEEP_DUPLICATES = keep duplicate strings
;               REMOVE_BLANKS  = remove blank strings
;
; History     : 6-May-2020, Zarro (ADNET) - written
;-

function str_same,input1,input2,count=count,keep_duplicates=keep_duplicates,$
                        remove_blanks=remove_blanks

count=0L
if ~is_string(input1,/blank) || ~is_string(input2,/blank) then return,''

d1=str_remove(input1,input2,count=c1,rcount=rc1,rindex=rindex1)
d2=str_remove(input2,input1,count=c2,rcount=rc2,rindex=rindex2)

if (rc1 eq 0) && (rc2 eq 0) then return,''
if rc1 ne 0 then r1=input1[rindex1]
if rc2 ne 0 then r2=input2[rindex2]

case 1 of
 (rc1 eq 0) && (rc2 ne 0): output=temporary(r2)
 (rc1 ne 0) && (rc2 eq 0): output=temporary(r1)
 else: output=[temporary(r1),temporary(r2)]
endcase

count=n_elements(output)
if ~keyword_set(keep_duplicates) then output=get_uniq(output,count=count)

if keyword_set(remove_blanks) then begin
 chk=where(trim2(output) ne '',count)
 if count eq 0 then output='' else begin
  if count lt n_elements(output) then output=output[chk]
 endelse 
endif

return,output
end
