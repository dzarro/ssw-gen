;+
; Project     : VSO
;
; Name        : ASCII_DECODE
;
; Purpose     : Decode % characters in URL string
;
; Category    : system utility sockets
;
; Syntax      : IDL> out=ascii_decode(in)
;
; Inputs      : IN = encoded string (e.g. %22)
;
; Outputs     : OUT = decoded string (e.g. ")
;
; Keywords    : None
;
; History     : 21 March 2016, Zarro (ADNET) - written
;               29 November 2019, Zarro (ADNET) - vectorized
;
; Contact     : dzarro@solar.stanford.edu
;-

function ascii_decode_i,sd
  s=sd
  s = str_replace(s,'+',' ')
  res = ''
  WHILE (i=strpos(s,'%')) GE 0 DO BEGIN
     res = res+strmid(s,0,i)
     temp=strmid(s,i+1,2)
     hex2dec,temp,byt,/quiet
     res = res+string(byte(byt))
     s = strmid(s,i+3,1e5)
  END
  res = res+s
  return,res
END

;---------------------------------------------------------------
FUNCTION ascii_decode,sd     

if is_blank(sd) then return,''

chk=where(strpos(sd,'%') gt -1,count)
if count eq 0 then return,sd

temp=sd[chk]
chk1=where(stregex(temp,'%[0-9,A-Z,a-z]{2}[^%]*(%[0-9,A-Z,a-z]{2})?',/bool),count1)
if count1 eq 0 then return,sd
for i=0,count1-1 do temp[chk1[i]]=ascii_decode_i(temp[chk1[i]])

out=sd
out[chk]=temporary(temp)
if n_elements(out) eq 1 then out=out[0]

return,out

end

