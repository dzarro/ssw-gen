pro ssw_jsmovie_modify, jshtml, replace=replace, backup=backup, $
  in_situ=in_situ, outdir=outdir, debug=debug, $
  orig_html=orig_html, modified_html=modified_html
;
;+
;   Name: ssw_jsmovie_modify
;
;   Purpose: update existing SSW javascript movie for AWS compatibility
;
;   Input Parameters:
;      jshtml - full path to the existing javascript movie
;
;   Keyword Parameters:
;      backup - (switch) - if set, make a backup of current <name>.html -> <name>.html.yymmdd
;      replace - (switch) - if setup, update existing js movie name
;      outdir - optional path for output html (won't work without graphics, but test .html diffs..)
;      orig_html - (output) - strarr contents of Before/existing javascript
;      modified_html - (output) - strarr contents of After (what shows up in updated file)
;
;   Calling Examples:
;      IDL> ssw_jsmovie_modify,'<name>.html' [,/replace] [,outdir='/path/'] [,/backup] [,orig_html=ohtml]
;
;   Calls:
;      usual suspects; rd_tfile, sstrarrinsert, str_replace, file_append
;
;   History:
;      4-May-2020 - S.L.Freeland, using David Schiff "by hand" AWS/Safari/Firefox tweak
;
;   TODO: 
;      allow url in place of path; (includes "stealing" graphics vis ssw_jsurl2imagelist
;      Get a more decriptive executive summary about AWS problem/safari issue/what this fix does
;      (I need to ask David, and I'll update this doc-header to clarify )
;      Add a keyword and/or environ. option to 'image2movie,/java' wrapper for post-production
;   
;   Restrictions:
;     I'd be amazed if there aren't any. 
;
;-

debug=keyword_set(debug)

case 1 of 
   n_params() eq 0: begin
      box_message,'Need input javascript html, local or url.. bailing'
      return ; !!!EARLY EXIT on no inpu js
   endcase
   file_exist(jshtml):  orig_html=rd_tfile(jshtml) ; local js movie
   strpos(jshtml,'http;') eq 0: begin
      sock_list,jshtmla,orig_html
      box_message,'http not yet supported'
      stop,'orig_hthml
   endcase
   else: begin
      box_message,'Need javadcript movie, local or url, bailing...
      return ; !!EARLY EXIT on bum input
   endcase
endcase

new_html=orig_html
mods=where(strpos(new_html,'// Modified: ') ne -1,mcnt)
thismod=where(strpos(new_html[mods],'ssw_jsmovie_modify') ne -1,tmcnt)
if tmcnt gt 0 then begin
   box_message,'This javascript html alread processed, bailing with no change'
   return ; !!! EARLY EXIT if already run
endif


; do the 1:1 replaces (e.g. # elements orig v. new remain the same
otno=["<img NAME=animation","images[index].onload"] ;,"document.animation"]
otnn=["<img id='animation' NAME=animation","//images[index].onload"] ;,"//document.animation"]
for i=0,n_elements(otno)-1 do begin
   ss=where(strpos(new_html,otno[i]) ne -1,sscnt)
   if sscnt ge 1 then new_html[ss]=str_replace(orig_html[ss],otno[i],otnn[i])
endfor

; add the Modification History here (now new v. orig line #s diverge)
new_html=strarrinsert(new_html,'// Modified: ' + anytim(reltime(/now),/yohkoh,/date_only) + ', by ssw_jsmovie_modify','// Modified',debug=debug,/last)
new_html=strarrinsert(new_html,'  images[index].decode().then(count_images);','images[index].src = urls[index];')
new_html=strarrinsert(new_html,/deldelim, $
   ['  if (images[num_loaded_images-1].complete) {', $
  '   document.animation.src=images[num_loaded_images-1].src;',$
  '}'],'  document.animation.src=images[num_loaded_images-1].src;')

animate=ssw_jsmovie_modify_animate(delim=delim)
new_html=strarrinsert(new_html,[animate,'{'],delim[0],delim[1],/deldelim)
modified_html=new_html ; just assign output keyword claimed in header...

; html/js tweaks done - optinally, write a file:

backup=keyword_set(backup)
replace=keyword_set(replace) or backup
break_file,jshtml,log,path,fname,ext
case 1 of
   file_exist(outdir): outfile=concat_dir(outdir,fname+ext) 
   keyword_set(replace): outfile=jshtml 
   else: box_message,'No file write implied, use OUTDIR, or /replace or /backup
endcase
if backup then file_move, jshtml, jshtml+'_'+time2file(reltime(/now),/date_only)
if keyword_set(outfile) then file_append,outfile,new_html,/NEW


return
end

