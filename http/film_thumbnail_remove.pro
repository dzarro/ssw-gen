pro film_thumbnail_remove,thumbfiles, thumbdir=thumbdir
;
;+
;   Name: film_thumbnail_remove
;
;   Purpose: remove film/sprocket holes from image2move/special_movie movie thumbnails - preserve the movie thumbnail Images (the useful piece)
;
;   Input Paramters:
;      thumbfiles - list of one or more movie thumbnails (image2movie/special_movie) - keyword THUMBDIR maybe more useful - does 'em all in there
;
;   Keyword Parameters:
;      thumbdir - path containing 'thumbfiles' ( usually MOVID_DIR used via image2movie/special_movie call)
;
;   History:
;      S.L.Freeland - Circa 2005, wnen 8/16 mm movie projectors fell out of vogue... remote the filmstrp/sprocket holes from heritage movie thumbnails.
;      25-aug-2020 - doc header only, added This doc header for posterity
;-


case 1 of 
   n_elements(thumbfiles) gt 0: thumbs=thumbfiles
   file_exist(thumbdir): thumbs=file_search(thumbdir,'*mthumb.gif')
   else: begin
      box_message,'Need thumbfiles list or THUMBDIR (path to thumbfiles)
      return
   endcase
endcase


nthumbs=n_elements(thumbs)
texist=where(file_exist(thumbs),nexist)

if nexist ne nthumbs then begin 
   box_message,'Cannot find one or more thumbfiles, bailing...'
   return
endif

for t=0,nthumbs-1 do begin
   dat=read_image(thumbs[t],r,g,b)
   tot=total(dat,1)
   miny=(where(tot eq min(tot) and shift(tot,-1) eq max(tot)))(0)
   maxy=last_nelem(where(tot eq min(tot) and shift(tot,1) eq max(tot)))
   if miny gt 0 and maxy gt miny then begin 
      newdat=dat[*,miny:maxy]
      file_copy,thumbs[t],thumbs[t]+'_backup' + '_' + time2file(reltime(/now)) ; save original for now
      write_gif,thumbs[t],newdat,r,g,b
   endif else box_message,'I believe that this thumbnail has already had filmstrip removed.., no action
   if get_logenv('check_nofilm') ne '' then stop,'thumbs[t],newdat.miny,maxy'
endfor

return
end  
