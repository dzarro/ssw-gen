;+
; Project     : VSO
;
; Name        : ASCII_ENCODE
;
; Purpose     : Encode special characters in URL string
;
; Category    : system utility sockets
;
; Syntax      : IDL> out=ascii_encode(in)
;
; Inputs      : IN = encoded string (e.g. '"')
;
; Outputs     : OUT = decoded string (e.g. %22)
;
; Keywords    : None
;
; History     : 10 January 2020 Zarro (ADNET) 
;               - copied from OSDC__DEFINE
;
; Contact     : dzarro@solar.stanford.edu
;-

FUNCTION url_encode_is_encoded_char,triplet
  
  IF strlen(triplet) LT 3 THEN return,0b
  
  hex_digits = '0123456789ABCDEFabcdef'
  c0 = strmid(triplet,0,1)
  c1 = strmid(triplet,1,1)
  c2 = strmid(triplet,2,1)
  
  IF c0 NE '%'                  THEN return,0b
  IF strpos(hex_digits,c1) LT 0 THEN return,0b
  IF strpos(hex_digits,c2) LT 0 THEN return,0b
  
  return,1b
END

; Genuine RFC2396 (sect. 2.3) url_encode, but does not encode '%' if
; followed
; by two hex digits (most likely a pre-encoded string!), unless the
; keyword
; encode_encoding_percent is set
;
FUNCTION ascii_encode,url,encode_encoding_percent=encode_encoding_percent
  
  encode_encoding_percent = keyword_set(encode_encoding_percent)
  IF is_blank(url) THEN return,''
  
  ; These characters do not need any encoding:
  ;
  safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" $
         +"abcdefghijklmnopqrstuvwxyz" $
         +'0123456789' $
         +"-_.!~*'()"
  
  ; Build output sequence of characters (encoded or not)
  ;
  length = strlen(url)
  out = strarr(length) ; Note - each entry may become more than one char!
  
  ; Consider each character separately
  ;
  FOR i=0,length-1 DO BEGIN
     ; Set-up:
     ;
     c = strmid(url,i,1)
     c_hex = '%'+string((byte(c))[0],format='(Z2.2)')
     
                                ; Do the next three characters look
                                ; like an encoded character? I.e. does
     ; it look like '%xx'?
     ;
     triplet = strmid(url,i,3)
     is_encoded_char = url_encode_is_encoded_char(triplet)
     
                                ; Unless explicitly told to encode the
                                ; '%' at the start of what looks
     ; like an already-encoded
     ;
     IF encode_encoding_percent THEN is_encoded_char = 0
     
     ; Now for the decision:
     ;
     ; If it's safe, then it's safe. 
     ; If it's '%', at the beginning of an encoded_char, then leave it
     ; If it's space, then it's '+'.
     ;
                                ; If none of the above, use hex
                                ; encoding - note that this includes
                                ;            '%' in
     ; '%xx' *if* /encode_encoding_percent is set!
     ;
     IF      strpos(safe,c) GE 0 THEN   out[i] = c     $
     ELSE IF is_encoded_char     THEN   out[i] = c     $
     ELSE IF c EQ ' '            THEN   out[i] = '+'   $
     ELSE                               out[i] = c_hex
  END
  
  return,strjoin(out,'')
END
