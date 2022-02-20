function align_label_cube, labels, cube, x,y,sx,sy, _extra=_extra, clobber=clobber
;
;+ 
;   Name: align_label_cube
;
;   Purpose: add labels to a data cube using align_lable.pro 
;
;   Input Parameters:
;      labels - vector of one or more labels
;      cube - optional data cube to label
;
;   Keyword Parameters:
;      clobber - if set and cube supplied, will clobber the input (memory)
;      _extra - all keywords accepted by align_label.pro (and xyouts, etc..)
;
;   Method:
;      use Z-buffer + align_label
;
;

nimg=data_chk(cube,/nim)
clobber=keyword_set(clobber)
nlab=n_elements(labels)

if nlab eq 0 then begin 
   box_message,'Assume you wanted to pass me some labels?, bailing... '
   return,-1
endif

dtemp=!d.name
case 1 of 
   clobber and nimg eq nlab: retval=temporary(cube)
   nimg eq nlab: retval=cube
   else:  begin
      wdef,xx,/zbuffer,im=intarr(512,512)
      llen=strlen(labels)
      ssb=where(llen eq max(llen))
      align_label,labels[ssb[0]],_extra=_extra,x,y,sx,sy
      retval=make_array(sx+1,sy+1,nlab,/byte)
    endcase
endcase

wdef,zz,/zbuff,im=retval
x=data_chk(retval,/nx)
y=data_chk(retval,/ny)
sx=-1
sy=-1
for i=0,nlab-1 do begin 
   tv,retval[*,*,i]
   align_label,labels[i],_extra=_extra,xi,yi,sxi,syi
   x=min([x,xi])
   y=min([y,yi])
   sx=max([sx,sxi])
   sy=max([sy,syi])
   retval[0,0,i]=tvrd()
endfor

set_plot,dtemp

return,retval
end


