; These programs generate Ryan Milligan's solar flare finder plots, save files, and database.
; A text file called last_update.txt keeps track of the latest time this was run for.
; Each run covers from 48 hours before that time to the present.
; When it's done, it rewrites last_update.txt with the present time.
; 
; Writes PNG files, SAV files, and a .txt catalog in /data/sff
;
; Normally runs from a cron job on gs671-hesperia.ndc.nasa.gov.
;
; Kim Tolbert, Aug 2017
; Modifications:
; 19-Sep-2017, Kim. Now sff_update_ssw_gev returns time range we're working with and we pass
;  that on to each routine, so everything is consistent


!quiet=1

cd, '/home/softw/sff'

ssw_gev_array = sff_update_ssw_gev(time_range=time_range, status=status)
if status then sff_finder, ssw_gev_array=ssw_gev_array, time_range=time_range, status=status
if status then sff_wrt_txt_file, time_range=time_range
if status then file_copy, 'last_update.txt', '/data/sff/last_update.txt', /overwrite, /verbose

end
