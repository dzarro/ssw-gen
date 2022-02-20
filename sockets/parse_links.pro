;+
; Project     : HESSI
;
; Name        : PARSE_LINKS
;
; Purpose     : Parse links in output listing
;
; Category    : utility system sockets
;
; Syntax      : IDL> links=parse_links(listing,file,path)
;                   
; Inputs      : LISTING = output listing of remote directory
;               FILE = remote file name or pattern to search 
;               PATH = optional path name to remove from links
;
; Outputs     : Matched results
;
; Keywords    : COUNT = # of matches
;               IMAGES = return IMG/SRC links instead of HREF
;
; History     : 7-Mar-2015, Zarro (ADNET) - Written
;               3-Mar-2019, Zarro (ADNET) - added IMAGES
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function parse_links,listing,file,path,count=count,images=images

 count=0
 img=keyword_set(images)
 if is_blank(listing) then return,''
 if is_string(file) then dfile=file else dfile='*'

 anyc='[^ "]*'
 dfile=str_replace(dfile,'.','\.')
 if strpos(dfile,'*') gt -1 then dfile=str_replace(dfile,'*',anyc) else dfile=anyc+dfile
 ireg=dfile+anyc

 if dfile eq anyc then ireg=anyc
 if img then item='src' else item='href'
 regex=item+' *= *"?('+ireg+') *"?.*>'

 dprint,'% Regex ',regex

;-- concatanate into single string and then split on anchor boundaries
;   [must do this so that multiple files per line get separated]

 temp=strsplit(strjoin(listing),'< *A +',/extract,/regex,/fold)
 match=stregex(temp,regex,/subex,/extra,/fold)
 chk=where(match[1,*] ne '',count)

 if count eq 0 then return,''
 links=reform(match[1,chk])
 chk=where(stregex(links,'^[^\?\/]',/bool),count)
 if count eq 0 then return,''
 links=links[chk]
 if count eq 1 then links=links[0]

;-- remove extra path from results

 if is_string(path) then begin
  chk=where(strpos(links,path) gt -1,scount)
  if scount gt 0 then links[chk]=str_replace(links[chk],path,'')
 endif

 return,links
 
 end


