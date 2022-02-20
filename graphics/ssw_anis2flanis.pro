pro ssw_anis2flanis, anismovie, htmldata, configdata, $
   write=write, outdir=outdir, object_only=object_only, debug=debug
;
;   Name: ssw_anis2flanis
;
;   Purpose: derive flash version of AniS/java movie, optionally write
;
;   Input Parameters:
;      anismovie - Anis applet array  or html file containing same 
;
;   Output Parameters:
;      htmldata - html snippet required to realize flash movie
;      configdata - FLanis configuration (param) array
;
;   Keyword Parameters:
;      write - (switch) - if set, write html + config file 
;      outdir - optional outdir; default derived from anismovie path
;      object_only - just html snippet, not full html doc
;
;   Restrictions:
;      for today, input <anismovie> is path, not applet
;
if 1-file_exist(anismovie) then begin 
   box_message,'Currently require html w/anis movie applet
   return
endif
debug=keyword_set(debug)

break_file,anismovie,ll,path,mname,mver,mext
mname=str_replace(mname+mver,'_a.html','')
mname=str_replace(mname,'+','__') ; "+" illegal in Flash(?)
anis=rd_tfile(anismovie)
apps=(where(strpos(anis,'<applet') ne -1,ascnt))(0)
appe=(where(strpos(anis,'</applet>') ne -1,aecnt))(0)
params=anis(apps+1:appe-1)
params=params(where(strpos(params,'<param') ne -1))
savegenx,file='params',params,/over
box_message,curdir(),nbox=2

params=ssw_strsplit(params,'<param name= ',/tail)
params=ssw_patt_replace(params,'"','')
params=ssw_patt_replace(params,'>','')
params=strtrim(ssw_strsplit(params,'value',/head),2) + '='+ strtrim(ssw_strsplit(params,'value',/tail),2)
imsizess=last_nelem(where(strpos(params,'image_window') ne -1,imcnt))

height='512'
width='512'
if imcnt gt 0 then begin 
   imsiz=str2arr(ssw_strsplit(params(imsizess),'=',/tail))
   width=imsiz(0)
   height=imsiz(1)

endif        

jarline=strcompress(strupcase(anis(apps)),/remove)
anissize=where(strpos(jarline,'HEIGHT') ne -1,scnt)
if scnt gt 0 then begin 
    height=strextract(jarline,'HEIGHT=','WIDTH=') 
    width=strextract(jarline,'WIDTH=','>')
endif
height=strtrim(fix(height+50)<2048,2) 
width=strtrim(fix(width)<2048,2)

flashdir=concat_dir(concat_dir(concat_dir('$SSW','vobs'),'gen'),'flash')
if not file_exist(flashdir) then flashdir= concat_dir('$SSW','site/idl/util')

flashswf=concat_dir(flashdir,'flanis.swf')
if not keyword_set(no_copy) then begin 
   spawn,['cp',flashswf,path],/noshell
   flashswf='flanis.swf'
endif
flashhtml=concat_dir(flashdir,'flanis.html')
cfgname=mname+'_flanis.cfg'
html=rd_tfile(flashhtml)
if keyword_set(object_only) then begin 
    ssobj=where(strpos(html,'OBJECT') ne -1)
    html=html(ssobj(0):ssobj(1))
endif
html=str_replace(html,'"620"','"'+width+'"')
html=str_replace(html,'"650"','"'+height+'"')
html=str_replace(html,'flanis.cfg',cfgname)
html=str_replace(html,'flanis.swf',flashswf)
params=strcompress(params,/remove)
params=str_replace(params,'active_zoom=false','active_zoom=true')
css=where(strpos(params,'controls=') ne -1, ccnt)
for i=0,ccnt-1 do begin 
   zchk=strpos(params(css(i)),',zoom') ne -1
   if zchk then begin 
      params(css(i))=str_replace(params(css(i)),',zoom','')

   endif
endfor
if ccnt gt 0 then params=[temporary(params),'active_zoom=true']


case 1 of 
   strpos(anismovie,'_a.html') ne -1: $
      flanishtml=str_replace(anismovie,'_a.html','_f.html')
   else: flanishtml=str_replace(anismovie,'.html','_f.html')
endcase 

html=[html,'<p>']
anishtml=rd_Tfile(anismovie)

html=strarrinsert(anishtml,html,'<applet','</applet',/deldelim)
ssobj=where(strpos(html,'<OBJECT class') ne -1)
ssobje=where(strpos(html,'</OBJECT>') ne -1)

if debug then stop,'html
html=[html(0:ssobj-1),'<font size=-1 color=brick><p><em>Flash<a href="http://www.ssec.wisc.edu/flanis/">(FlAniS)</a>',$
   ' animation; left click to zoom, click & drag to pan, select color table via Pick Enhancement menu</em></font><br>',html(ssobj:ssobje),'<p><font size=-2><em>', $
'<a href="http://www.ssec.wisc.edu/flanis/"> FlAniS software</a> ', $
'courtesy University of Wisconsin-Madison Space Science & Engineering Center</em></font>',html(ssobje+1:*)] 
file_append,flanishtml,html,/new
file_append,concat_dir(path,cfgname),params,/new

return
end
;      
;        
