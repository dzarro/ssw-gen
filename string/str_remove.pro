;+
; Project     : VSO
;
; Name        : STR_REMOVE
;
; Purpose     : Remove matching strings from a string
;
; Category    : utility strings
;
; Syntax      : IDL> output=str_remove(input,remove)
;
; Inputs      : INPUT = scalar or vector of strings to check
;               ELEMENTS = scalar or vector of strings to remove from input
;
; Outputs     : OUTPUT = remaining string after removal ('' if nothing left)
;
; Keywords    : COUNT = # of remaining elements in INPUT
;               REGEX = elements is Reg Exp
;               FOLD_CASE = match is case-insensitive
;               INDEX = indicies of kept elements in INPUT
;               RINDEX = indicies of removed elements from INPUT
;               RCOUNT = # of removed elements
;
; History     : 15-Jan-2019, Zarro (ADNET) - written
;               15-Sep-2019, Zarro (ADNET) - added RCOUNT
;               26-Nov-2019, Zarro (ADNET) - fixed bug when removing all elements
;                7-May-2020, Zarro (ADNET) - allow blank strings in input
;               28-Oct-2020, Zarro (ADNET) - replaced is_string with
;                                            faster isa
;               7-July-2021, Zarro (ADNET) - replace isa() with is_blank()
;-

function str_remove,input,elements,count=count,fold_case=fold_case,$
                    index=index,regex=regex,err=err,rindex=rindex,rcount=rcount

err=''
index=-1L
rindex=-1L
rcount=0L
count=n_elements(input)
if is_blank(input) then begin
 count=0 & return,''
endif

count=n_elements(input) & index=lindgen(count)
if is_blank(elements) then return,input

ocount=count
oindex=index
fold_case=keyword_set(fold_case)

if keyword_set(regex) then begin
 if n_elements(elements) ne 1 then begin
  err='Regexp must be scalar string.'
  return,input
 endif
 temp=strjoin(strsplit(elements,'|',/extrac),'|')
 index=where(~stregex(input,temp,/bool,fold_case=fold_case),scount)
endif else begin
 if fold_case then $
  index=rem_elem(strlowcase(input),strlowcase(elements),scount) else $
   index=rem_elem(input,elements,scount)
endelse

if scount ne count then begin
 if scount gt 0 then begin
  output=input[index] & count=scount
 endif else begin
  output='' & count=0
 endelse 
endif else output=input

if count eq 1 then begin
 output=output[0]
 index=index[0]
endif

if count gt 0 then begin 
 rindex=rem_elem(oindex,index,rcount)
endif else begin
 rindex=oindex
 rcount=ocount
endelse

if rcount eq 1 then rindex=rindex[0]

return,output
end
