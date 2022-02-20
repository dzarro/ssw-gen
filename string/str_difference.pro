;+
; Project     : VSO
;
; Name        : STR_DIFFERENCE
;
; Purpose     : Return strings that are not in either array
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_difference(input1,input2)
;
; Inputs      : INPUT1 = scalar or vector of strings to check
;             : INPUT2 = scalar or vector of strings to check
;
; Outputs     : OUTPUT = strings that are not in INPUT1 or INPUT2
;
; Keywords    : COUNT = # of returned results
;               KEEP_DUPLICATES = keep duplicate strings
;               REMOVE_BLANKS  = remove blank strings
;
; History     : 31-Dec-2019, Zarro (ADNET) - written
;                7-May-2020, Zarro (ADNET) - allow blank strings in input
;               28-Oct-2020, Zarro (ADNET) - replaced is_string with faster isa
;-

function str_difference,input1,input2,count=count,keep_duplicates=keep_duplicates,$
                        remove_blanks=remove_blanks

count=0L
if ~isa(input1,/string) || ~isa(input2,/string) then return,''

d1=str_remove(input1,input2,count=c1)
d2=str_remove(input2,input1,count=c2)

if (c1 eq 0) && (c2 eq 0) then return,''

case 1 of
 (c1 eq 0) && (c2 ne 0): output=temporary(d2)
 (c1 ne 0) && (c2 eq 0): output=temporary(d1)
 else: output=[temporary(d1),temporary(d2)]
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
