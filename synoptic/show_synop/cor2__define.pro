;+
; Project     : STEREO
;
; Name        : COR2__DEFINE
;
; Purpose     : stub that inherits from SECCHI class
;
; Category    : Objects
;
; History     : Written 7 April 2009, D. Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

;-----------------------------------------------------------------

function cor2::search,tstart,tend,_ref_extra=extra

return,self->secchi::search(tstart,tend,det='cor2',_extra=extra)
end

;-----------------------------------------------------------------

pro cor2::read,file,_ref_extra=extra

self->secchi::read,file,det='cor2',_extra=extra

return
end

;---------------------------------------------------------------
pro cor2__define,void                 

void={cor2, inherits secchi}

return & end
