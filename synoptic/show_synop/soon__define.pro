;+
; Project     : RHESSI
;
; Name        : SOON__DEFINE
;
; Purpose     : Class definition for SOON H-alpha data object
;
; Category    : Objects
;
; History     : 4 July 2018, Zarro (ADNET) - written
;               11 Aug 2018, Zarro (ADNET) - switched to using WCS2MAP
;               03-Oct-2018, Kim - changed host from soon.colorado.edu to soonar.colorado.edu
;
; Contact     : dzarro@solar.stanford.edu
;-

function soon::init,_ref_extra=extra

ret=self->fits::init(_extra=extra)
if ~ret then return,ret

ret=self->site::init(_extra=extra)
if ~ret then return,ret

self->setprop,rhost='ftp://soonar.colorado.edu',delim='/',/full,$
      org='day',topdir='/SOONAR',ftype='SOON',ext='fits',/month_name

return,1

end

;--------------------------------------------------------------------------
;-- search SOON archive 

function soon::search,tstart,tend,_ref_extra=extra,count=count,type=type

type=''
files=self->site::search(tstart,tend,_extra=extra,count=count)
if count gt 0 then type=replicate('H-alpha/images',count) else files=''
return,files
end

;-----------------------------------------------------------------------------
;-- determine the positions in arcseconds from Sun center of the reference pixel.

function soon::get_wcs,header

if is_blank(header) then return,null()
wcs_temp = fitshead2wcs(header)
date = wcs_temp.time.observ_date

pangle=(pb0r(date))[0]
rsun0 = asin(wcs_rsun() / wcs_temp.position.dsun_obs) * !radeg * 3600
rsun = rsun0 * fxpar(header, 'rv')
angle = !dtor * (fxpar(header, 'pa') - pangle)
crval = [-rsun * sin(angle), rsun * cos(angle)]

;-- generate a new WCS in HPC coordinates.

wcs = wcs_2d_simulate( wcs_temp.naxis[0], wcs_temp.naxis[1], $
                       crpix=wcs_temp.crpix, crval=crval, $
                       cdelt=wcs_temp.cdelt, cunit=['arcsec','arcsec'], $
                       date_obs=wcs_temp.time.observ_date, $
                       crota2=-pangle )

return,wcs
end

;--------------------------------------------------------------------
;-- make SOON image map

pro soon::mk_map,index,data,i,_ref_extra=extra,filename=filename,$
                 no_roll_correct=no_roll_correct

roll_correct=~keyword_set(no_roll_correct)
if ~have_tag(index,'filename') then index=add_tag(index,'','filename')
if is_string(filename) then index.filename=file_basename(filename)

get_fits_par,index,id=id
header=struct2fitshead(index,data,_extra=extra)
wcs=self->get_wcs(header)
newheader = wcs2fitshead(wcs)
newindex=fitshead2struct(newheader)
wcs2map,data,wcs,map,id=id,_extra=extra
if roll_correct then map=rot_map(map,roll=0,/no_copy)
self->set,i,map=map,/no_copy
self->set,i,index=newindex
self->set,i,header=newheader
self->set,i,grid=30,/limb,_extra=extra
self->set_colors,i,index

return & end

;----------------------------------------------------------------------------

pro soon::cleanup

self->fits::cleanup
self->site::cleanup

return & end

;-----------------------------------------------------
pro soon__define,void                 

void={soon, inherits fits, inherits site}

return & end
