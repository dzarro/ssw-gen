pro special_movie2,  index,  data,  r, g, b, movie_name=movie_name, $
     debug=debug,  _extra=_extra, movie_dir=movie_dir, $
     movie_text=movie_text, grid_minutes=grid_minutes, nolabel=nolabel, $
     local=local, html=html, no_htmldoc=no_htmldoc, outsize=outsize, $
     context=context, ctitle=ctitle, filter=filter,$
     no_gifanimate=no_gifanimate, anis_java=anis_java, $
     flanis=flanis, flash=flash
;+
;   Name: special_movie
;
;   Purpose: make sxt movies for WWW (just set up and call image2movie)
;
;   EXAMPLE: REPRESENTATIVE OUTPUT FROM SPECIAL_MOVIE IS AVAILABLE AT: 
;      http://www.lmsal.com/solarsoft/ssw_movie_making.html
;
;   Input Parameters:
;      index - time structures (any SSW format)     
;      data  - 3D array
;      r,g,b - optional RGB values
;   
;    Keyword Parameters:
;      movie_name - top level movie name (XXX.html) and used as root name
;                   for associated files for organizational purposes
;      movie_text - optional text description (included in html doc)
;                   -OR- filename conatining description
;      grid_minutes - optional cadence for pseudo-regular sampling
;                     (subset of index,data closest to time grid)
;      nolabel - if set, dont auto-label movie frames (default puts
;                time tags on frames 
;      local - if set, use current directory for everything
;
;      no_htmldoc - if set, dont make the top level html doc
;                   (useful for appending to existing doc via SW)
;      html (OUTPUT) - the HTML (table with thumbnail, links to movies,
;                    statistics etc.
;      context - if set, name(s) of context files to include
;                if 1 element - inline html
;                if 2 element - assumed thumbnaile/full
;      no_gifanimate - if set, only JS&Mpeg
;      anis_java (switch) - if set ,include AniS Java version
;  
;
;
;      XXX - ALL OTHER KEYWORDS USED BY IMAGE2MOVIE, including:
;         table - IDL color table #
;         reverse - reverse Color table
;         gamma - color table gamma
;         outsize - frame size for MOVIEs (data is congridded/rebinned)
;         thumbsize - frame size for movie icons
;
;   History:
;      10-July-1996 (S.L.Freeland)
;      25-July-1996 (S.L.Freeland) - broke html -> mk_movie_html
;      21-aug-1997  (S.L.Freeland) - new technol (image2movie.pro)
;      21-oct-1997  (S.L.Freeland) - keywords->image2movie (inheritance)
;       8-Apr-1998  (S.L.Freeland) - add /NONLABEL switch
;      14-Apr-1998  (S.L.Freeland) - add /LOCAL switch, documentation
;       8-May-1998  (S.L.Freeland) - fix typo in LABEL
;       1-Jun-1999  (S.L.Freeland) - reduced workload by ~50% - pass files back->image2movie
;      11-Aug-1999  (S.L.Freeland) - movie_dir pass through!, only filter data on request
;      11-Nov-1999  (S.L.Freeland) - improved appearence of output HTML
;      09-May-2003, William Thompson - Use ssw_strsplit instead of strsplit
;      23-may-2008  (S.L.Freeland) - add /NO_GIFANIMATE switch
;      12-aug-2008  S.L.Freeland - add /ANIS_JAVA keyword 
;      30-oct-2014  S.L.Freland - add ffmpeg support (via image2movie2)
;  
;   NOTE: Movie making Brains are in <image2movie.pro> - this is just
;   a convenient wrapper which calls that routine once for each of 
;   three formats (mpeg, javascript, gif-animate) 
;   see doc header for <image2movie.pro> routine for more details/options.
;-
debug=keyword_set(debug)

if n_elements(movie_name) eq 0 then movie_name='special_'+ time2file(index(0))

; --------------------- set up device/path ----------------
dtemp=!d.name
set_plot,'z'
case 1 of 
   file_exist(movie_dir):
   keyword_set(local): begin
      configure_http,/local
      movie_dir=curdir()
   endcase
   n_elements(movie_dir) gt 0: begin 
      configure_http,movie_dir,'.'
   endcase
   else: begin 
      movie_dir =concat_dir(curdir(),'movies')
   endcase
endcase
mk_dir,movie_dir
if not file_exist(movie_dir) then begin 
   box_message,'No write access to> ' + movie_dir,'Please create & supply MOVIE_DIR keyword next call.. bailing'
   return ; EARLY EXIT on no write/movie_dir
endif

if not keyword_set(thumbsize) then thumbsize=200       ; increased 200 (bigger displays...) 10-nov-2014 

tempdir=curdir()
cd,movie_dir
hdoc=concat_dir(movie_dir,movie_name+'.html')
; -----------------------------------------------------------

; ----------------- initialize ------------------------------------
tindex=index
allhtml=''
newhtml=''
mroot=movie_name
message,/info,"Generating movie : " + movie_name
if keyword_set(grid_minutes) then begin           
   ss=grid_data(index,min=grid_minutes,/ss)
   index=index(ss)
   data=data(*,*,ss)
endif  
; -----------------------------------------------------------

if keyword_set(filter) then quality_filter, index, data                  ; filter out bad frames
flash=keyword_set(flash) or keyword_set(flanis)
anis=keyword_set(anis_java) or flash
nogif=keyword_set(no_gifanimate) or anis ; /ANIS implies /NO_GIFANIMATE
whirgif=ssw_bin('whirlgif',found=found) 
nogif=nogif or (1-found) 

case 1 of 
   anis: mtype=str2arr('java,anis,mpeg')
   nogif: mtype=str2arr('java,mpeg')
   else: mtype='java,gif,mpeg'  ; historical default 
endcase
   
; ----- generate movies, one  per mtype via image2movie.pro -------------
if not keyword_set(nolabel) then label=anytim(index,out='ECS')

if n_elements(ctitle) eq 0 then ctitle='Context Image'
for i=0, n_elements(mtype)-1 do begin           ; for each movie output fmt...
if debug then stop,"preimage2movie,mtype[i],concat_dir(movie_dir,mroot+'_'+strmid(mtype(i),0,1))"
   image2movie2,data,r,g,b,  /nodelete, $
       movie_name=concat_dir(movie_dir,mroot+'_'+strmid(mtype(i),0,1)), $
       uttimes=index, label=label, /inctime, $
       debug=debug, $
       _extra=_extra, html=html, movie_dir=movie_dir, $
       anis=(mtype(i) eq 'anis'), $
       java=(mtype(i) eq 'java'), mpeg=(mtype(i) eq 'mpeg'), $
       loop=(mtype(i) eq 'gif'),  gif=(mtype(i) eq 'gif'), outsize=outsize, $
       write_video=(mtype(i) eq 'mpeg') and since_version(8.2) and is_member(!version.os,'linux,sunos'), $
       context=context, ctitle=ctitle, tempfiles=tempfiles, verbatim=(i ne 0)  

   if n_elements(idata) eq 0 then idata=temporary(data)  
   data=tempfiles                                        ; reuse temp files
   newhtml=[newhtml,html]                                ; running html
endfor 

data=temporary(idata)                          ; return pristine input

; -----------------------------------------------------------
;  ----------- reformat HTML for 3 format table -----------------
thumb=strextract(newhtml(2),'<IMG SRC','>',/include)   ;gif thumb
case n_elements(context) of
   0: conthtml=''
   1: conthtml='<IMG SRC="' + context(0) + '">'
   else: begin
      conthtml=strtab2html(transpose( $
       [ctitle,str2html(context(0) , link_text=context(1),/nopar) ]))
   endcase
endcase   

head=[thumb,newhtml(1),strextract(newhtml(2),'Fram','<br>',/inc),'<br>']

; ------ make table out of movie URLs --------
movstats=strextract(newhtml(2),'Fram','<br>',/inc)
movurls=ssw_strsplit(newhtml([2,4,6]),'Frame Size')+'</B></A>'
if n_elements(mtype) eq 2 then movurls=movurls(0:1)
movtable=strtab2html(movurls,pad=1,spac=1,border=1)
; ---------------------------------------------

if flash then begin 
   aname=movie_name+'_a.html'
   amovie=concat_dir(movie_dir,aname)
   ssw_anis2flanis,amovie
   movtable(1)=str_replace(movtable(1),'a.html','f.html')
   movtable(1)=str_replace(movtable(1),'Java(AniS)','Flash(FlAniS)')
endif

; --- Main Table (movie statistics / thumbnail / movie links) ---
movstats=arr2str([newhtml(1),movstats],'')
maintab=strtab2html(transpose([movstats,thumb,arr2str(movtable,'')]))
if conthtml(0) ne '' then maintab=[                                        $
    '<table border=2 cellpadding=2 cellspacing=2>',                        $
    '<tr align=center><td>',conthtml,'</td><td>',maintab, '</td></table>']
; ---------------------------------------------

; ------ prepend optional user text --------
if data_chk(movie_text,/string) then begin
   if file_exist(movie_text(0)) then movie_text=rd_tfile(movie_text)
   allhtml=[str2html(movie_text),'<p>', allhtml]
endif
; ---------------------------------------------

;  ------------- write an html document ----------------
allhtml=[allhtml,maintab]
if not keyword_set(no_htmldoc) then begin 
   html_doc,hdoc,/header
   file_append,hdoc,allhtml
   html_doc,hdoc,/trailer
endif
;  ------------------------------------------------------
html=allhtml                             ; define keyword output

prstr,strjustify(['Completed HTML, URL:',http_names(hdoc)],/box)
index=tindex
if debug then stop
set_plot,dtemp
cd,tempdir
configure_http,/reset          ; restore original http environmnet
return
end
