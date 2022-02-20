pro ssw_ffmpeg,infiles, moviename, _extra=_extra,movie_dir=movie_dir, movie_name=movie_name, mp4=mp4, avi=avi, extension=extension, size_movie=size_movie, $
   verbatim=verbatim, noclobber=noclobber, bit_rate=bit_rate, frame_rate=frame_rate, help=help, debug=debug, nogif=nogif
;+
;   Name: ssw_ffmpeg
;
;   Purpose: list of 2D graphic files or input video stream -> output video stream via ffmpeg (called by image2movie.pro for /mp4 or /avi options, for example)
;
;   Input Parameters:
;      files - list of files to encode; *gif, *png, *tiff -or- input video stream file (.mpg,mp4,avi...) to convert/modify
;
;   Output Parameters:
;      moviename - full path to ffmpeg generated video file
;
;   Keyword Parameters:
;      movie_name - desired root of movie name (implies format if extension is present)
;      movie_dir - output path for moviefile - NOTE: output moviename=<movie_dir>/<movie_name>.<extension>
;      mp4 (switch) - if set, mp4 output (default)
;      avi (switch) - if set, avi output
;      verbatim (string) - optional verbatim string passed -> ffmpeg (assumes ffmpeg expertise..) 
;      help (switch) - if set, just call ffmpeg with help switch and show output (warning: vebose)
;      _extra - optional/unspecified PARAM:VALUES passed -> ffmpeg
;
;   History:
;      circa 1-aug-2014 - S.L.Freeland - mpeg_encode alternate using "more modern" ffmpeg
;      25-oct-2014 - S.L.Freeland - documentation, assure INFILES paths fully qualfied (avoid hiccup if in CD/relative)
;      
;
;   Note: starting in IDL V8.2.3, intrinsic support for video streams
;   was enhanced (read_vide, write_video etc...) - this routine 
;   helps fill some OS/ARCH gaps and 2D files->video gaps (and
;   see image2movie.pro heritage api which does/will shortly use this
;   to extend to mp4, avi, and other ffmpeg capabilities
;
;   Restrictions:
;      Only small subset of ffmpeg options described; currently a simple api maybe transitional/older IDL version (<8.2.3)
;-
debug=keyword_set(debug)
ffmp=ssw_bin_path('ffmpeg',/ontol,found=found)
if not found then begin
   box_message,'ffmpeg not yet online for This OS/Arch - send IDL> help,!version,/str output -> freeland@lmsal.com , SUBJ:ffmpeg'
   return
endif

if keyword_set(help) then begin 
   spawn,[ffmp,'-h'],/noshell,out
   box_message,out
   return ; !!! EARLY EXIT on /HELP
endif

nf=n_elements(infiles)
if nf eq 0 then begin 
   box_message,'Need input filelist'
   return
endif

files=infiles
fex=file_exist(files)
ess=where(fex,ecnt)

if ecnt lt nf then begin
   box_message,'One or more of your input files does not exist. bailing...'
   return
endif

if strpos(files[0],'/') eq -1 then files=concat_dir(curdir(),files) ; assure absolute path

if strpos(files[0],'.') eq -1 then begin
   box_message,'Expect a list of one or more graphics files (including .{gif,png,tiff...} extensions. bailing...'
   return ; EARLY EXIT on non-graphics list input
endif

iext=('.' + ssw_strsplit(files[0],'.',/tail) )(0)

ext='.mp4'
case 1 of 
   keyword_set(avi): ext='.avi'
   keyword_set(mp4): ext='.mp4'
   data_chk(movie_name,/string):if strpos(movie_name,'.') ne -1 then ext='.'+ssw_strsplit(movie_name,'.',/tail)
   else: ext='.mp4'
endcase

verb=keyword_set(verbatim)

nosymlinks=keyword_set(nosymlinks) ; use input filelist verbatim ; caveat emptor
nodelete=keyword_set(nodelete) or nosymlinks ; don't delete "scratch" files/symlinks

if n_elements(movie_name) eq 0 then movie_name='ffmpeg_'+time2file(reltime(/now),/sec)+'_'+ssw_strsplit(get_logenv('$IDL_STARTUP'),'.',/tail)
if n_elements(movie_dir) eq 0 then movie_dir=get_temp_dir()
sroot=(([movie_name,ssw_strsplit(movie_name,'.',/head)])(strpos(movie_name,'.') ne -1))(0)
if strpos(sroot,'/') ne -1 then sroot=ssw_strsplit(sroot,'/',/tail)
sroot=sroot[0]

scratchdir=concat_dir(movie_dir,sroot)

if nosymlinks then begin ; assume already 
   inlist=files
endif else begin ; create symlinks
   mk_dir,scratchdir
   lnames=sroot+string(lindgen(nf),format='(I5.5)') + iext
   inlist=concat_dir(scratchdir,lnames)
if get_logenv('check_delete') then stop,'inlist'
   ssw_file_delete,inlist 
   for l=0,nf-1 do spawn,['ln','-s',files[l],inlist[l]],/noshell
endelse

if n_elements(bit_rate) eq 0 then bit_rate=30000 ; K
if n_elements(frame_rate) eq 0 then frame_rate = 30

if not required_tags(_extra,'r')  then _extra=add_tag(_extra,frame_rate,'r')
if not required_tags(_extra,'bv') then _extra=add_tag(_extra,bit_rate,'bv')
if not required_tags(_extra,'qscale') then _extra=add_tag(_extra,2,'qscale')

pv=[''] ; force overwrite of ouput file
if not data_chk(movie_dir,/string) then movie_dir=concat_dir(path_http,'movies')
etags=strlowcase(tag_names(_extra))
for t=0,n_tags(_extra)-1 do begin
   ett=etags[t]
   if is_member(ett,'bv') then ett=strmid(ett,0,1)+':' + strmid(ett,1,1)
   pv=[pv,'-'+ett]
   pv=[pv,strtrim(_extra.(t),2) + (['','K'])(ett eq  'b:v')]
endfor

pattern=sroot+'%05d'+iext
pattern="'"+pattern+"'"

temp=curdir()
cd,scratchdir
moviename=concat_dir(movie_dir,sroot)+ext

verbose=(['-v 0 ',''])(debug)

cmd=arr2str([ffmp,verbose + '-y -i',pattern,pv,moviename],' ')
cmd=cmd+(['',' </dev/null'])(get_logenv('IDL_BATCH_RUN') ne '')

if debug then stop,"prespawn: spawn,[ffmp,pv,'-i',pattern,moviename],/noshell, ; CMD"
box_message,cmd
;spawn,[ffmp,'-y','-i',pattern,pv,moviename],/noshell
spawn,arr2str(cmd,' ')
if debug then stop,'post'


cd,temp



return
end
