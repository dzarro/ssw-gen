;+
; Project     : VSO
;
; Name        : HMI_SUNSPOT
;
; Purpose     : Label sunspots on HMI image and write to JPEG
;
; Category    : imaging
;
; Syntax      : IDL> hmi_sunspot,date
;
; Inputs      : DATE = date to display
;
; Outputs     : JPEG file in current directory
;
; Keywords    : GSIZE = image dimensions (def=[1024,1024])
;               SOURCE_ID = Helioviewer SOURCE_ID (def = 18)
;
; History     : 29 May 2016, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

pro hmi_sunspot,date,err=err,_extra=extra,gsize=gsize,source_id=source_id

err=''

;-- get nearest HMI/Continuum JPE2000 image from Helioviewer

if ~valid_time(date) then get_utc,date,/vms
if ~is_number(source_id) then source_id=18
hv_get,date,source_id,local=local,out_dir=get_temp_dir(),err=err
if is_string(err) then return

;-- set up Z-buffer for plotting

if n_elements(gsize) ne 2 then gsize=[1024,1024]
dsave=!d.name
set_plot,'Z'
device,set_resolution=gsize,decomposed=0,set_pixel_depth=24,$
  set_character_size=[5,5],set_font='Times',/close

;-- convert JPEG2000 image to map and label sunspots

jpeg2map,local,map,err=err
map.id='SDO HMI'
if is_string(err) then return
plot_map,map,/noaxes,/date_only,_extra=extra
nar=get_nar(map.time,count=count,/nearest,/quiet)
if count gt 0 then nar=drot_nar(nar,map.time,count=count)
if count gt 0 then oplot_nar,nar,_extra=extra,off=[0,40],font=-1
out=tvrd(/true)
device,/close
set_plot,dsave

;-- write Z-buffer image to JPEG

t1=anytim2tai(date)
dcode=date_code(t1)
outdir=curdir()
if ~file_test(outdir,/write,/dir) then begin
 err='No write access to '+outdir
 mprint,err
 return
endif

gfile=concat_dir(outdir,'sunspots_'+strtrim(string(gsize[0]),2)+'_'+dcode+'.jpg')
mprint,'Writing JPEG file to -> '+gfile
write_jpeg,gfile,out,qual=100,/true

return & end
