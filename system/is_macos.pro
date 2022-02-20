;+
; Project     : VSO
;
; Name        : IS_MACOS
;
; Purpose     : Return true if Mac OS
;
; Category    : utility system
;
; Syntax      : IDL> chk=is_macos()
;
; Inputs      : None
;
; Outputs     : CHK = true if Mac OS
;
; Keywords    : None
;
; History     : 15-Sep-2019, Zarro (ADNET)
;-


function is_macos

os='' & os_name=''
if have_tag(!version,'OS') then os=strlowcase(!version.os)
if have_tag(!version,'OS_NAME') then os_name=strcompress(strlowcase(!version.os_name),/remove_all)

return,(os eq 'darwin') || (os_name eq 'macosx')
end
