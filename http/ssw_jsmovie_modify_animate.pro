function ssw_jsmovie_modify_animate, delimit=delimit
;
;+ 
;    Name: ssw_jsmovie_modifiy_animate
;
;    Purpose: return javsascript movie snippet ; safari/firefox update for AWS migration
;
;    History:
;      4-may-2020 - S.L.Freeland - per David Schiff example
;     27-aug-2020 - S.L.Freeland - look in gen/idl/http for the .js snippet text file
;
;-
animate_js=concat_dir('$SSW_ONTOLOGY','idl/gen_temp/ssw_jsmovie_modify_animate.js')
if ~file_exist(animate_js) then animate_js=concat_dir('$SSW','gen/idl/http/ssw_jsmovie_modify_animate.js')
retval=rd_tfile(animate_js)
delimit=[retval[0], last_nelem(retval)] ; where to stick it in original html (via strarrinsert)

return,retval
end
