;+
; Project     : STEREO
;
; Name        : EUVI__DEFINE
;
; Purpose     : stub that inherits from SECCHI class
;
; Category    : Objects
;
; History     : Written 7 April 2009, D. Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-


pro euvi::mk_map,index,data,k,_ref_extra=extra

self->secchi::mk_map,index,data,k,_extra=extra,/log

return & end

;-----------------------------------------------------------

pro euvi::read,file,_ref_extra=extra

self->secchi::read,file,detector='euvi',_extra=extra

return & end

;-----------------------------------------------------------

function euvi::search,tstart,tend,_ref_extra=extra

return,self->secchi::search(tstart,tend,detector='euvi',_extra=extra)

end

;----------------------------------------------------
pro euvi__define,void                 

void={euvi, inherits secchi}

return & end
