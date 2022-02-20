pro image2movie2, filelist, r, g, b,                                     $
   movie_name=movie_name, outsize=outsize,  				$
   nodelete=nodelete, cycle=cycle, goes=goes, 				$
   thumbnail=thumbnail, thumbfile=thumbfile, tframes=tframes,   	$
   thumbsize=thumbsize, nothumbnail=nothumbnail,                        $
   framethumb=framethumb, 						$
   notfilm=notfilm, notlabel=notlabel,                                  $
   table=table, gamma=gamma, reverse=reverse, currentcolor=currentcolor,$
   low=low, high=high, 							$
   uttimes=uttimes, deltat=deltat, label=label, inctime=inctime,	$
   outdir=outdir, movie_dir=movie_dir,                                  $
   scratchdir=scratchdir, 						$
   html_array=html_array, debug=debug,                               	$
   gif_animate=gif_animate, mp4=mp4, avi=avi, mpeg=mpeg, _extra=_extra,	$
   ffmpeg=ffmpeg, $
   write_video=write_video, $
   fmt_time=fmt_time, out_style=out_style, loop=loop,                   $
   flash=flash, anis=anis, java=java, tempfiles=tempfiles,                           $
   still=still, tperline=tperline, server=server,                       $
   context=context, ctitle=ctitle, verbatim=verbatim,                   $
   labstyle=labstyle, maxxy=maxxy, corexy=corexy, $
   controls=controls, bottom_controls=bottom_controls
;+
;   Name: image2movie   
;
;   Purpose: convert an image file sequence (3d, gif, jpeg) to desired fmt (mpeg,gif-anim,java,still,javascript)
;    
;   URL Reference: http://www.lmsal.com/solarsoft/ssw_movie_making.html
;
;   Input Parameters:
;       filelist - list of gif or jpeg image files (generally chronological order)
;             -OR- 3D data cube
;       r,g,b    - optional color table (default is from files or assigned)
;   
;   Keyword Parameters:
;      movie_name - output file name (default is derived) (extension =.gif or.mpg)
;                   (default written to $path_http/movies)
;      outsize - specify frame size (default is size in image)
;      goes - if set, merge goes lightcurve / timeline
;      thumbnail - if set, generate a movie thumbnail
;      thumbfile - (input/output) thumbnail file name 
;      thumbsize - if set, thumbnail frame size (def=64)
;      nothumbnail - if set, dont make thumbnail (/THUMBNAIL now the default)
;      framethumb - also generate a single frame thumb (def=multiframe thumb strip)
;                  (if -1, selected mid-frame, else desired frame SS 0->1st frame  10000->last frame...)
;      uttimes   - UT times of images [ array of lenght(nfiles) ]
;                  Can automatically derive from file name ...YYMMDD.HHMM[SS]...
;      deltat    - relative times between images (in place of absolute uttimes)
;                  (array of length(nfiles) or switch (/deltat) to imply unity
;      scratchdir - if defined, use this directory for temporary files
;                   (defaults to '$SSW_MOVIE_SCRATCH' or $path_http/movie_scratch')
;      html_array (output) - html descripter and link to insert in html document
;                            (if thumbnail, this is included as a SRC link)
;      inctar     - switch - if set and uttimes supplied, include time range
;                            in output HTML_ARRAY
;      tperline - (still only) - thumbnails per line
;      out_style / fmt_time (synonyms) - time-> label format
;                  (via get_infox. See anytim.pro OUT_STYLE options)
;                              {ECS,CCSDS,YOHKOH...}                  
;      loop -  switch, gif animate only - set loop flag in gif header
;
;      gif,mpeg,java,still,anis,mp4,avi - format switches - (exclusive) specify output format 
;      context - name of GIF movie context image (ex FD w/movie FOV annotated)
;      ctitle - optional title for optional context image
;      verbatim - if FILELIST supplied and /VERBATIM , do not regenerate temporary files
;      notlabel - if set, dont time stamp thumbnails
;      notfilm  - if set, dont put film perferations on film thumbnail.
;      maxxy - limit size of thumbnail to this -> mkthumb (for example,
;              for high aspect ratio frames)
;      ffmpeg - if set, swap in ffmpeg for mpeg_encode if both exist for This OS/Arch
;
;   Calling Sequence:
;      IDL> image2movie ,infiles, /gif_animate [,r,g,b, outsize=XY, KEYWORDS..]
;      IDL> image2movie ,infiles, /mpeg        [,r,g,b, outsize=XY, KEYWORDS..]
;      IDL> image2movie ,data3D, /mpeg         [,r,g,b, outsize=XY, KEYWORDS..]
;
;   Calling Examples:
;      IDL> image2movie, filelist,/gif [,/loop]         ; gif animate (w/defaults)
;      IDL> image2movie, fileslist,/mpeg	        ; mpeg        (w/defaults)
;      IDL> image2movie, fileslist,/java	        ; java        (w/defaults)
;      IDL> image2movie, data3D,   /java	  ; same using 3D data cube
;      IDL> image2movie, filelist,outsize=256           ; rebin 
;      IDL> image2movie, filelist, r,g,b                ; new color table
;      IDL> image2movie, filelist, table=NN, gamma=.nn  ; same, use IDL table
;
;      IDL> image2movie, filelist, labels=labelarray                ; label
;      IDL> image2movie, filelist, uttimes=timearr, /label          ; label w/time
;      IDL> image2movie, filelist, uttimes=timearr, /goes, /label   ; add GOES
;
;      IDL> image2movie, filelist,/thumbnail, html_array=html_array ; HTML link
;      IDL> image2movie, data, uttimes=timearr, /java               ; data->files->javsscript movie
;      IDL> image2movie, data, utimes=timarr, /ANIS                 ; same -> Java/AniS 
;           ( AniS via: http://sohowww.nascom.nasa.gov/solarsoft/gen/idl/http/ssw_javamovie.pro )
;      

;   History:
;     16-nov-1995 (SLF) - convert sxt2mpeg -> image2mpeg (semi-generic)
;     29-jul-1996 (SLF) - avoid function/variable conflict (mkthumb)
;     10-feb-1997 (SLF) - add LABEL keyword and function
;      4-mar-1997 (SLF) - use ssw_bin.pro to find executables - documentation
;      5-mar-1997 (SLF) - combine image2gifanim&image2mpeg-> image2movie
;                         Cleanup, add Documentation
;      6-mar-1997 (SLF) - add HTML_ARRAY output (insert in html documnent)
;     15-mar-1997 (SLF) - add INCTIME keyword, adjust HTML_ARRAY output slightly
;     18-mar-1997 (SLF) - add FMT_TIME/OUT_STYLE (synonyms) for time-label style
;                         add THUMBSIZE parameter (->mkthumb.pro)
;     15-jul-1997 (SLF) - add /JAVA switch (call DMZ jsmovie.pro)
;     21-jul-1997 (SLF) - swing mode option for java option
;     22-jul-1997 (SLF) - add /STILL option (ok, not a movie option, but most
;                         of the function is the same...)
;     21-oct-1997 (SLF) - allow direct data cube input
;     27-oct-1997 (SLF) - permit mpeg parameter file in $SSW_SETUP
;     28-oct-1997 (SLF) - work around anytim(/date,/trunc,out='ECS') bug
;     29-oct-1997 (SLF) - suppress some diagnostics, add /truncate to anytim)
;      2-Mar-1998 (SLF) - fix path problem with mpeg (caused an rgb problem)
;     14-Apr-1998 (SLF) - made SCRATCHDIR more robust
;     12-Oct-1998 (SLF) - add CONTEXT keyword and function - restore use
;                         of DMZ default JS template html file
;      1-Jun-1999 (SLF) - add VERBATIM keyword and function, add /RANGE to jsmovie
;     12-Aug-1999 (SLF) - dont override MOVIE_DIR with $path_http(!)
;                         Add seconds to scratch filenames (avoid file name conflicts)
;     14-Sep-1999 (SLF) - add some documentation, pointer to SSW movie URL
;     17-Nov-1999 (SLF) - add /NOTFILM and /NOTLABEL - use 'ssw_deltat'
;     14-Jan-2000 (SLF) - eliminate blank thumbnail frames (permit duplicates)
;     17-Jan-2000 (SLF) - truncate diagnostic movie commands 
;      09-May-2003, William Thompson - Use ssw_strsplit instead of strsplit
;     12-aug-2008 (SLF) - merge a few enhnancments; maxxy & corexy -> mkthum
;                         add /ANIS keyword & function (hooks to ssw_javamovie.pro via AniS applet
;     28-jul-2014 (SLF) - ffmpeg hooks (mp4, avi...)
;     16-jul-2015 (SLF) - /write_video keyword & function (use IDL intrinsic for +=V8.2
;  
;   Restrictions:
;      need executables  'whirlgif'                       (gif animations) -OR-
;                        'mpeg_encode' and 'giftopnm'     (mpeg) -OR-
;                        'ffmpeg' (mp4/avi)
;                       Javascript, Java(/ANIS), and Still formats all *.pro
;
;      If file names do not include UT TIME (...YYMMDD.HHMM...), it is advisable
;      to pass in a DELTA-T or UTTIMES array (or use /deltat if you dont care)
;-

debug=keyword_set(debug)
case 1 of
   n_elements(tframes) ne 0:
   n_elements(tperline) ne 0: tframes=tperline
   else: tframes=8
endcase
  
case 1 of 
   data_chk(fmt_time,/scalar,/string):
   data_chk(out_style,/scalar,/string): fmt_time=out_style
   else: fmt_time='yohkoh'                                 ; default 
endcase

iext=''
if n_elements(movie_name) eq 0 then movie_name=''
if strpos(movie_name,'.') ne -1 then begin 
   mroot=ssw_strsplit(movie_name,'.',/head,tail=iext)
endif 
  
flash=keyword_set(anis) or keyword_set(flanis) or keyword_set(flash) ; all these use common suite
mpeg=keyword_set(mpeg) or iext eq 'mpg' 
mp4=keyword_set(mp4) or   iext eq 'mp4'
avi=keyword_set(avi) or   iext eq 'avi' 
gifanimate=keyword_set(gifanimate) or iext eq 'gif' ; historical default is gifanimate (TODO - re-anable this via ffmpeg/newer OS/ARCH)
java=keyword_set(java) ; actually, heritage use of /JAVA=javascript 
anis=keyword_set(anis) or flash
still=keyword_set(still)
verbatim=keyword_set(verbatim)
write_video=keyword_set(write_video) ; use New (finally) IDL/exelis read/write video objects (via write_video.pro wrapper)

; format dependent stuff
exten='.html' ; used for javascript/still/flash
ffencode=ssw_bin_path('ffmpeg',found=efound,/ONTOLOGY)
ffmpeg=0
eok=1
case 1 of 
   write_video: begin
      encode='write_video' ; IDL intrinsic >= 8.2
      exten='.'+(['avi','mp4'])(mp4 or mpeg)
      if ~since_version('8.2') then begin
         box_message,'/WRITE_VIDEO requested, but current IDL version is < required >=8.2, bailing with no action'
         return  ; !!! EARLY EXIT on < required IDL verions
      endif
      eok=1
box_message,'/WRITE_VIDEO set
   endcase
   mp4 or avi or (mpeg and efound): begin 
      exten='.'+(['avi','mp4'])(mp4 or mpeg)
      eok=efound
   endcase
   mpeg: begin
      encode=ssw_bin('mpeg_encode',found=efound,/warning)
      giftopnm=ssw_bin('giftopnm',  found=g2pnmfound ,/warning)
      eok=encode and g2pnmfound 
      exten='.mpg' ; historical /MPEG option via mpeg_encode path
   endcase
   java or flash or still or anis: 
   (strlen(iext) ge 1 and strlen(iext) le 4 ) and efound: begin
      exten=iext
      eok=efound
      box_message,'Trying ffmpeg, since I dont know what else to do with this file type...'
   endcase
   else: begin ; historical gifanimate default (I should have started vine.com 20 years ago...)
      encode=ssw_bin('whirlgif', found=eok,/ warning)
      exten='.gif'
   endcase
endcase
if debug then stop,'eok,exten

path_http=get_logenv('path_http')                  
top_http=get_logenv('top_http')

; if binary required, bail if encoding executables for This OS/ARCH not in distribution
if get_logenv('check_eok') ne '' then stop,'_extra'
if not eok then begin
   box_message,/info,["Dont have required executables for requested animation...", $
      "send cut&paste image2movie command line + output from IDL> help,!version,/str", $
      "to freeland@lmsal.com, SUBJ: image2movie OS/ARCH format problem", $
      "bailing...."]
   return
endif

cdir=curdir()
if keyword_set(movie_dir) then scratchdir=movie_dir
if keyword_set(outdir) then scratchdir=outdir

; -------------- determine directory for temporary/scratch files ----------- 
if not keyword_set(scratchdir) then scratchdir=get_logenv('SSW_MOVIE_SCRATCH')
if scratchdir eq '' then scratchdir=concat_dir(path_http,'movie_scratch')
if not file_exist(scratchdir) then scratchdir=concat_dir(path_http,'movies')
if not file_exist(scratchdir) then scratchdir=curdir()

if not file_exist(scratchdir,/dir) then begin
   message,/info,"No SCRATCH directory: " + scratchdir
   message,/info,"Create one and try again or use SCRATCHDIR input parameter"
   return
endif
; -------------------------------------------------------------------------

curfid=time2file(ut_time(),/sec)        ; yyyymmdd_hhmmss NOW
id=curfid

newtable=keyword_set(table) or keyword_set(gamma) or keyword_set(reverse)
goes=keyword_set(goes)
reverse=keyword_set(reverse)
tvlct,rr0,gg0,bb0, /get ; preserve original RGB

; --------- if goes, load a combined table (image + bright plot colors) ----------
if newtable then begin
   if goes then begin
      line_table, table, gamma=gamma, reverse=reverse 
   endif else begin
      if not keyword_set(low) then low=0
      if not keyword_set(high) then high=!d.table_size
      if not keyword_set(gamma) then gamma=1
      loadct,table
      stretch,([low,high])(reverse),([high,low])(reverse), gamma
   endelse
   tvlct,r,g,b,/get
endif
; ------------------------------------------------------------------

cd,scratchdir
newfil=filelist

if not data_chk(newfil,/string) then begin              ; 
  data2files, filelist, times=uttimes, /gif, file=newfil, $
	 autoname=(1-keyword_set(uttimes)), outdir=outdir
endif 

nds=n_elements(newfil) 

break_file,newfil(0),ll,pp,ff,ee

; ------------- determine frame times (absolute or relative times) -------------
utime=0
case 1 of
   n_elements(deltat) eq nds: uttimes=anytim2ints(ut_time(),off=deltat)
   n_elements(deltat) eq 1:   uttimes=anytim2ints(ut_time(),off=lindgen(nds)*deltat)
   n_elements(uttimes) eq nds: utime=1
   total(strspecial(ff+ee)) ge 10 : utfids=extract_fid(newfil,times=uttimes,fidfound=fidfound)
   else: begin
      uttimes=anytim2ints(ut_time(),off=lindgen(nds))
   endcase
endcase
uttimes=anytim(uttimes,out_style=fmt_time,/truncate)
secs=int2secarr(uttimes)
; ----------------------------------------------------------------------------

; --------------------- label frames on request ------------------------------
case 1 of
   n_elements(label) eq 0:
   data_chk(label,/string): if n_elements(label) eq nds then imglab=label $
      else imglab=replicate(label,nds)
   data_chk(label,/scaler): begin
      imglab=fmt_tim(uttimes)      
   endcase
   else:
endcase
; ----------------------------------------------------------------------------

break_file,newfil,nlogs,npaths,nfnames,next,nver
mfile_list=nfnames + next + nver
if not file_exist(movie_dir) then movie_dir=curdir()
mk_dir,movie_dir
mk_dir,scratchdir

if java or still then scratchdir=movie_dir

if not keyword_set(movie_name) then movie_name= $
    concat_dir(movie_dir,'img2movie_' + id)

break_file,movie_name,ll,mpath,mname,mext,mver
mname=mname+mext+mver

movie_name=str_replace(movie_name,exten,'') + exten  ; assure 1 (and only 1)
newcolor= keyword_set(b)		; color table passed
rebinit = keyword_set(outsize)

; ------- Generate movie thumbnail on request (via mkthumb.pro) ---------------
thumbnail=(1-still) and (1-keyword_set(nothumbnail))    ; slf, 5-mar-1997 - THUMBNAIL now defaul
if n_elements(thumbsize) eq 0 then thumbsize=150
if thumbnail then begin
   if not data_chk(thumbfile,/string,/scalar) then $
      thumbfile=str_replace(movie_name,exten,'_mthumb.gif')
   iconfile=str_replace(thumbfile,'mthumb','micon')  
   fthumbfile=str_replace(thumbfile,'mthumb','fthumb')   ; single frame thumbname
   ss=grid_data(uttimes,nsamp=tframes<(n_elements(uttimes)-1))  ; 
endif

if n_elements(ss) eq 0 then ss=lindgen(n_elements(secs))
; ----------------------------------------------------------------------------

; --- Cases which require temporary files (new size, color table, etc) -------
if (keyword_set(outsize) or goes or newcolor or thumbnail or $
   (n_elements(imglab) gt 0)) and (1-verbatim) then begin
   i=0
   read_str='read_gif,newfil(i),image' + ([',r,g,b',''])(newcolor)
   print,read_str
   init=execute(read_str)
;  -------- determint output size (rebin required?) ----------------
   simg=size(image)
   case n_elements(outsize) of
      0: outs=[simg(1),simg(2)]
      1: outs=[outsize,outsize]
      2: outs=outsize
   endcase
   tdat=bytarr(outs(0),outs(1),n_elements(ss))
   tempfiles=concat_dir(scratchdir,nfnames + $
		str_replace(next,'.gif','') + '.gif')
   if java or still then tempfiles=str_replace(tempfiles,'.gif','_'+id+'.gif')
   prstr,strjustify(["Writing temporary files...",tempfiles],/box),/nomore
   tcnt=-1
   dtemp=!d.name

;  ----------- Temporary file read/rewrite loop -----------------------------
   for i=0,n_elements(newfil)-1 do begin
      readone=execute(read_str)
      if rebinit then image=congrid(image,outs(0),outs(1))      
      if n_elements(imglab) gt 0 then begin
         wdef,im=image,/zbuff
         set_plot,'z'
         tv,image
         if data_chk(labstyle,/string) then begin
	     estring='align_label,imglab(i),' + labstyle(0)
	     estat=execute(estring)
	 endif else xyouts,5,10,imglab(i),/dev            ; original label
         zbuff2file, tempfiles(i),r,g,b,/gif             ; rewrite via zbuff2file
      endif else  write_gif,tempfiles(i),image,r,g,b
if debug then stop,'zbuff,imglab'

      tss=where(i eq ss,tsscnt)
      for ti=0,tsscnt-1 do tdat(0,0,tss(ti))=image
  endfor
;  ----------------------------------------------------------
   set_plot,dtemp
   npaths(*)=''
endif else begin
   case 1 of
      verbatim: begin
          box_message,'VERBATIM - not regenerating tempfiles...'
	  tempfiles=filelist
          read_gif,filelist(0),img
	  outs=[data_chk(img,/nx), data_chk(img,/ny)]
      endcase
      pp(0) eq '': tempfiles=concat_dir(curdir(),newfil) 
      else: tempfiles=newfil
   endcase
   tdat=mkthumb(ingif=tempfiles(ss),maxxy=maxxy, corexy=corexy,  $
      outsize=thumbsize,/nofilm)
   tdat=reform(tdat,data_chk(tdat(*,*,0),/nx)/n_elements(ss),$
	            data_chk(tdat(*,*,0),/ny),n_elements(ss))

endelse
; ----------------------------------------------------------------------------

; ----------------------- generate thumnails --------------------------------
if thumbnail then begin
   dayonly=ssw_deltat(uttimes([ss(0),last_nelem(ss)])) gt 2*86400.
   timeonly=1-dayonly
   if not keyword_set(notlabel) then $
      labtimes=anytim(uttimes(ss),out_style=fmt_time, date=dayonly, time=timeonly,/truncate)
   if goes then tdat=bytscl(tdat,top=!d.table_size-14)+16
   thumb=mkthumb(tdat,r,g,b,outsize=thumbsize,outfile=thumbfile, /frame, $
         corexy=corexy, maxxy=maxxy, labels=labtimes, nofilm=notfilm , labstyle=labstyle)
   if n_elements(thumbsize) eq 0 and n_elements(maxxy) gt 0 then $
      thumbsize=maxxy
   icon=mkthumb(tdat,corexy=corexy, maxxy=maxxy, r,g,b,outsize=fix(float(thumbsize)*.5),outfile=iconfile,/frame,/nofilm)
   if n_elements(framethumb) gt 0 then begin 
      nmthumb=data_chk(tdat,/nimage)
      if framethumb eq -1 then fss=nmthumb/2 else fss=framethumb<(nmthumb-1) 
      fthumb=mkthumb(bytscl(sigrange(tdat(*,*,fss))),r,g,b,outsize=thumbsize*1.3,outfile=fthumbfile,corexy=corexy, /nofilm)
   endif
endif
; ----------------------------------------------------------------------------

if npaths(0) ne '' then inpath=npaths(0) else inpath = scratchdir
if pp(0) eq '' then npaths(*)=curdir() 

nimg=n_elements(mfile_list)
imgseq=lindgen(nimg)				; default image pointers

; ----------------------------------------------------------------------------
if keyword_set(cycle) then begin		; cycle = forward/time reversal
   imgseq=[imgseq,reverse(imgseq)]
   imgseq=reform(rebin(imgseq,nimg*2,cycle,/samp),cycle*nimg*2)   
endif 
; ----------------------------------------------------------------------------

prstr, strjustify(strjustify(tempfiles) + ' ' + $
       file_size(tempfiles,/str,/auto), /box),/nomore

; -------------- Movie type specific code --------------------------------------
if n_elements(ctitle) eq 0 then ctitle='Context Image'
 
useffmpeg=eok and file_exist(ffencode) and (mpeg or avi or mp4)
if java or still or anis or useffmpeg or write_video then begin
  
   msize=file_size(tempfiles,/total,/string,/auto)
   break_file,tempfiles,ll,pp,ff,ee,vv
   case 1 of
      write_video: begin 
         f0=read_image(tempfiles[0])
         video_dims=[data_chk(f0,/nx),data_chk(f0,/ny)]
         write_video,movie_name,handle=handle,mk_24bit(f0,r,g,b), video_dimensions=video_dims,video_fps=24
         for f=0,n_elements(tempfiles)-1 do begin 
            frame=read_image(tempfiles[f])
            if data_chk(frame,/ndimen) eq 2 then frame=mk_24bit(frame,r,g,b) ; 24b
            write_video,movie_name,handle=handle,frame
         endfor
         write_video,/close,handle=handle
         mtype=strupcase(ssw_strsplit(movie_name,'.',/tail))
          msize=file_size(movie_name,/string,/auto)

box_message,'wrote>> ' + movie_name,nbox=5
      endcase
      useffmpeg: begin 
          box_message,'Using ffmpeg'
          if debug then stop,'pre ffmpeg, tempfiles,movie_name,movie_dir'
          ssw_ffmpeg,tempfiles,moviename,movie_name=movie_name,movie_dir=movie_dir
          mtype=strupcase(ssw_strsplit(moviename,'.',/tail))
          msize=file_size(moviename,/string,/auto)
          if debug then stop,'post ffmpeg, moviename,mtype,msize'
      endcase
      java: begin
         if keyword_set(context) then jsmovie,movie_name,ff+ee,$
		  title=str_replace(mname,'.html',''), $
		  context=context(0), ctitle=ctitle, /range  else $
         jsmovie,movie_name,ff+ee, title=str_replace(mname,'.html',''), /range
         mtype='JavaScript'
      endcase

      anis: begin 
         box_message,'anis,ff,ee,movie_name,name
         ssw_javamovie,ff+ee,applet,_extra=_extra, $
            controls=controls, bottom_controls=bottom_controls
         mdoc=movie_name ; concat_dir(movie_dir,movie_name)
         html_doc,mdoc,/header
         file_append,mdoc,applet
         html_doc,mdoc,/trailer
         mtype='Java(AniS)'

      endcase

      still: begin
         if keyword_set(tperline) then tpl=tperline else tpl=nds < 5
         mtype='Stills'
         tnames=str_replace(tempfiles,'.gif','_mthumb.gif')
         for i=0,nds-1 do out = mkthumb(ingif=tempfiles(i), $
              outfil=tnames(i),nx=thumbsize(0), $
              corexy=corexy, maxxy=maxxy, label=labels)

         stable=str2html(http_names(tempfiles,/rel), $
	    link_text=str_replace(http_names(tempfiles,/rel),'.gif','_mthumb.gif'),/nopar)
         glabs=uttimes
         if n_elements(label) gt 0 then glabs=label
         stable=str_replace(stable,'</A>','<br><em>') + glabs +'<br>GIF (' + $
		 file_size(tempfiles,/string,/auto)+')</em></A>'
         embed=strarr(tpl* (nds/tpl+1)) & embed(0)=stable
         table=reform(embed,tpl,n_elements(stable)/tpl+1)
         stillurl=strtab2html(table,border=2,pad=2)
      endcase
      else: return
   endcase   
endif else begin
   if mpeg then begin
      mpeg_template='mpeg_encode.param'
      param_file=concat_dir(['$SSW_SETUP',path_http],mpeg_template)    ; MPEG t$
      pwhere =where(file_exist(param_file),pwcnt)
      if pwcnt eq 0 then begin
         prstr,/nomore,strjustify(['No MPEG parameter file found in: ', $
                                    param_file],/box)
         return
      endif else param_file=param_file(pwhere(0))
      params=rd_tfile(param_file)                             ; read TEMPLATE
      outparam=concat_dir(scratchdir,id + '_mpeg.param')      ; THIS parameter file
;     ----- substitute specific MPEG parameters --------------
      params=str_replace(params,'!MOVIE_NAME!',movie_name)
      params=str_replace(params,'!INPUT_CONVERT!',gif2pnm)
      if data_chk(tempfiles,/string) then inpath = scratchdir else inpath=npaths(0)
      params=str_replace(params,'!INPUT_PATH!',inpath)
      ifss=(where(strpos(params,'!INPUT_FILTER!') gt 0,ifcnt))(0)
;     concatentate image list with mpeg paramters 
      nimg=n_elements(mfile_list)
      imgseq=lindgen(nimg)                            ; default image pointers
      if keyword_set(cycle) then begin                ; cycle = forward/time reversal
         imgseq=[imgseq,reverse(imgseq)]
         imgseq=reform(rebin(imgseq,nimg*2,cycle,/samp),cycle*nimg*2)   
      endif 
      params=[params(0:ifss-1),mfile_list(imgseq),params(ifss+1:*)]
      file_append,outparam,params,/new                ; write new param file
      movie_cmd = encode + ' ' + outparam
;  --------------------------------------------------------
   endif else begin
      sloop=' '
      if keyword_set(cycle) then sloop = ' -loop ' + strtrim(cycle,2) + ' '
      if keyword_set(loop) then sloop  = ' -loop '
      break_file,tempfiles,ll,pp,ff,ee,vv
      movie_cmd=encode + ' -o ' + movie_name + sloop + arr2str(tempfiles,' ')
   endelse
   mtype=(['GIF Animation','MPEG'])(mpeg)
   message,/info,"Spawning movie generation command (" + mtype + ")"
   if keyword_set(server) then movie_cmd=movie_cmd + ' >& /dev/null'
   prstr,strjustify(['Movie Command',$
	  strmid(movie_cmd,0,100)+(['','...'])(strlen(movie_cmd) gt 100)],/box),/nomore
   spawn,str2arr(movie_cmd,' '),/noshell,status
   msize=file_size(movie_name,/string,/auto)
   delete = n_elements(tempfiles) ne 0 and (1-keyword_set(nodelete))
   if delete then file_delete,tempfiles
endelse
; ----------------------------------------------------------------------------

start=ut_time()

if mpath eq '' then begin
   mpath=curdir()
   movie_name=concat_dir(mpath,movie_name)
endif

movie_url=http_names(movie_name,/relative)  ;         path->URL conversion
movie_url=str_replace(movie_url,'http://./','')

if not still then prstr,strjustify(["Movie written to ",  movie_name, $
  "URL: ", movie_url ],/box),/nomore
stopt=ut_time()
; ----------------------------------------------------------------------------

; ------------------ form textual movie description and HTML ----------------
mframes=strcompress(string([outs,n_elements(imgseq)], $
        format='("Frame Size: ",i4," x ", i4," #Frames: ", i4)'))
mtitle=mtype + " " + strtrim(msize,2)  + " " + mframes
if not keyword_set(thumbfile) then thumbfile=''
thumburl=http_names(thumbfile)
if strpos(movie_url,'http://') eq -1 then begin
  movie_url=ssw_strsplit(movie_url,'/',/last,/tail)
  thumburl= ssw_strsplit(thumburl,'/',/last,/tail)
endif

if still then html_array=stillurl else $
   html_array=str2html(movie_url,link=mtitle+'<br> '+ thumburl,/nopara)

if utime and keyword_set(inctime) then begin
   fmt_timer,uttimes,t0,tn
   t0=anytim(t0,out_style=fmt_time,/truncate)
   tn=anytim(tn,out_style=fmt_time,/truncate)
   html_array=['<em>' + t0 + '<b> to </b> ' + tn +'</em><br>', $
               html_array]   
endif

cd,cdir
return
end
