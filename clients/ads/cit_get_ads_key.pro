
FUNCTION cit_get_ads_key, status=status, quiet=quiet

;+
; NAME:
;      CIT_GET_ADS_KEY()
;
; PURPOSE:
;      This routine checks if the user has an ADS key and returns the
;      key value.
;
; CATEGORY:
;      ADS; citations.
;
; INPUTS:
;      None.
;
; OPTIONAL OUTPUTS:
;      Status:   If the key file is found then status=1 else
;                status=0.
;
; KEYWORDS:
;      QUIET:  If set, then no information messages are printed.
;
; OUTPUTS:
;      A string containing the ADS key. If not found, then an empty
;      string is returned.
;
; MODIFICATION HISTORY:
;      Ver.1, 30-Nov-2015, Peter Young
;-

output=''

;
; Get ADS API dev_key
;
search_dir=concat_dir(getenv('HOME'),'.ads')
IF NOT keyword_set(quiet) THEN $
   print,'Searching for the ADS key in the directory '+search_dir
dev_key_file=concat_dir(search_dir,'dev_key')
chck=file_search(dev_key_file,count=count)

IF count EQ 0 THEN BEGIN
  IF NOT keyword_set(quiet) THEN print,'**ADS key not found.**'
  status=0
  return,output
ENDIF ELSE BEGIN
  status=1
ENDELSE 

openr,lin,dev_key_file,/get_lun
str1=''
readf,lin,str1
free_lun,lin
output=trim(str1)

IF output NE '' AND NOT keyword_set(quiet) THEN BEGIN
  print,'ADS key found'
ENDIF 

return,output

END
