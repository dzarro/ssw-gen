
function get_tty_type, file=file, qdebug=qdebug
;+
;NAME:
;	get_tty_type
;PURPOSE:
;	Return the terminal type by comparing the environment variable
;	DISPLAY to a lookup list in $GSE_BASE_DIR/.MDI_HOSTS        
;SAMPLE CALLING SEQUENCE:
;	ttype = get_tty_type()
;HISTORY:
;	Written 4-May-94 by M.Morrison
;	30-Nov-95 (MDM) - Modified to use .XTERMS file instead of .MDI_HOSTS
;	 4-Nov-96 (MDM) - Added protection if the .XTERMS file does not
;			  exist.
;        5-Nov-97 (DMZ) - added check for GSE_BASE_DIR
;-
;
common get_tty_typ_blk, tty_list
;
disp = getenv('DISPLAY')
node = getenv('HOSTNAME')
;
if (keyword_set(qdebug)) then print, 'DISPLAY=' + disp + '  HOSTNAME=' + node
;
p = strpos(disp, ':')
p2 = strpos(disp, '.')
if (p2 ne -1) and (p2 lt p) then p = p2
p = p>0
;
node0 = strmid(disp, 0, p)
if (keyword_set(qdebug)) then print, 'NODE0='+node0
;
if (node0 eq '') then node0 = node	;defined as ":0" or ":0.0"
;
if (n_elements(file) eq 0) then file = concat_dir(getenv('GSE_BASE_DIR'),'.XTERMS')
if (not file_exist(file)) then return, '????'		;MDM added 4-Nov-96
if (n_elements(tty_list) eq 0) then tty_list = rd_tfile(file, 3)
;
ss = where(node0 eq tty_list(0,*), n)
if (n eq 0) then out = '????' $
	    else out = tty_list(2,ss(0)) + tty_list(1,ss(0))
;
return, out
end

