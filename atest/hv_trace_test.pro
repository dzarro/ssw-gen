
; test script to read and process TRACE images for Helioviewer

pro hv_trace_test,tstart,tend,_ref_extra=extra
  
common trace_test, tobj

;- initialize TRACE object

if ~obj_valid(tobj) then tobj=obj_new('trace') 

files=tobj->search(tstart,tend,_extra=extra,count=count,/verbose)

if count eq 0 then begin
 mprint,'No matching files found'
 return
endif

;-- read files into memory (just do first one for testing)

count=1
for i=0,count-1 do begin
 tobj->read,files[i],_extra=extra,err=err
 if is_string(err) then return
 tobj->plot,/use
 index=tobj.index
 image=t->scale(index,tobj.data,/byte)

 HV_TRACE2_PREP2JP2,index,image,hvs=hvs

 details = hvs.hvsi.details
 jp2_filename = HV_FILENAME_CONVENTION(hvs.hvsi,/create)

 HV_WRITE_JP2_LWG,jp2_filename,hvs.img,hvs.hvsi.write_this,fitsheader = hvs.hvsi.header,$
   details = details,measurement = hvs.hvsi.measurement

endfor

return & end
