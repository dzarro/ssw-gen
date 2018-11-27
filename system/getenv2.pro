;+
; Project     : RHESSI
;
; Name        : GETENV2
;
; Purpose     : Wrapper around GETENV that checks for preceding $ & ~
;
; Category    : system utility
;
; Inputs      : VAR = scalar string variable to check
;
; Outputs     : OVAR = expanded environment variable
;
; Keywords    : PRESERVE = return VAR if not expanded
;
; History     : 17-Oct-2018 Zarro (ADNET) - written
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function getenv2,var,preserve=preserve

ovar=''
if is_blank(var) then return,ovar
svar=var[0]

if strpos(svar,'~') gt -1 then begin
 evar=expand_tilde(svar)
 if evar ne svar then return,evar
endif

ovar=getenv(svar)
if is_blank(ovar) then begin
 doll=strpos(svar,'$')
 if doll eq 0 then begin
  evar=strmid(svar,1,strlen(svar))
  tvar=getenv(evar)
  if is_string(tvar) then ovar=tvar
 endif
endif

if is_blank(ovar) && keyword_set(preserve) then ovar=var

return,ovar
end
