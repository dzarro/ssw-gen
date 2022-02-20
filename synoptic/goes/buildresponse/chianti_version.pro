;+
; PROJECT:
;     CHIANTI
;
; PURPOSE:
;     Return the installed CHIANTI package version 
;
; CALLING SEQUENCE:
;       chianti_version, version
; July 2020, RAS, modified to use rd_ascii()
;-

pro chianti_version, vers

  vers = rd_ascii( concat_dir(concat_dir('ssw_chianti','dbase'),'version'))
  vers=strtrim(vers,2)
  if (strlen(vers) lt 2) then vers = 'XXX'

end
