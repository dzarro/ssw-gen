
; test script to read and process TRACE images for Helioviewer

pro hv_trace_test,tstart,tend,_ref_extra=extra
  
common trace_test, tobj

if ~valid_time(tstart) || ~valid_time(tend) then begin
 pr_syntax,'hv_trace_test,tstart,tend
 return
endif

;- initialize TRACE object

if ~obj_valid(tobj) then tobj=obj_new('trace') 

;-- search for files in TRACE catalog

files=tobj->search(tstart,tend,_extra=extra,count=count,/vso)

if count eq 0 then begin
 mprint,'No matching files found'
 return
endif

;-- read files into memory (just do first one for testing)

count=1
for i=0,count-1 do begin
 tobj->read,files[i],_extra=extra
 index=tobj.index
 data=trace_scale(index,tobj.data,/byte)
 hv_trace_prep2jp2,index,data
endfor

return & end
