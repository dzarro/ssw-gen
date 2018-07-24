;+
; Project     : HESSI
;
; Name        : MK4__DEFINE
;
; Purpose     : Class definition for Mauno Loa Solar Observatory MK4 coronagraph images
;
; Category    : Objects
;
; History     : Written 27-Apr-2016, Kim Tolbert
;               Modifed 29-Apr-2016, Zarro 
;               - removed READ, SEARCH, and PARSE_TIME methods as
;                 these are handled in FITS and SITE
;
; Contact     : kim.tolbert@nasa.gov
;-

function mk4::init, _ref_extra=extra

if ~self->site::init(_extra=extra) then return,0
if ~self->fits::init(_extra=extra) then return,0

rhost = 'mlso.hao.ucar.edu'
self->setprop, rhost=rhost, org='day', delim='/', telim='.', $
  topdir='/hao/archive/acos', /full,regex='mk4\.rpb\.vig\.fts\.gz',$
  dtype='Coronagraph/images'

; URLs look like this:
; e.g. 'http://mlso.hao.ucar.edu/hao/archive/acos/2005/09/07/20050907.185452.mk4.rpb.vig.fts.gz

return, 1
end

;----------

pro mk4__define
void = {mk4, inherits fits, inherits site}
return & end
