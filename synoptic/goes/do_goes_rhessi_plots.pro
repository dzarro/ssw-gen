;+
;Name: do_goes_rhessi_plots
;
;Purpose: Run goes_rhessi_plot to make GOES plots showing RHESSI obs times for RHESSI Browser
;  (http://sprg.ssl.berkeley.edu/~tohban/browser/). If no arguments are provided, default is 
;  to make the most recent 15 days of plots, including the current day. Two types of daily 
;  plots are created - 24 hour, and stacked 12 hour plots - and there are plots on RHESSI
;  orbit times (midnight to midnight) (not generated after RHESSI died in Aug 2018).
;  Unless the test keywords is set, this should be run on hesperia. The plots are written to
;  /data/goes/ in directories 24hr_plots, 12hr_plots, and /rhessi_orbit_plots.
;  These are normally run from a cron job by account softw on hesperia  that does the following:
;    do_goes_rhessi_plots
;    do_goes_rhessi_plots, /stacked
;    do_goes_rhessi_plots, /orbit
;  To run manually for a specific time interval, run commands like this:
;    do_goes_rhessi_plots, time=['1-jan-2021','18-aug-2021']
;    do_goes_rhessi_plots, time=['1-jan-2021','18-aug-2021'], /stacked
;    and another one with /orbit if before before Aug 2018.
;    
;Input Keywords:
;  time - if scalar, day to start making plots (makes ndays plots)
;     if 2-element array, time range to make plots for (ndays ignored in this case)
;     Default is current time
;  ndays - number of days to make plots for. Default is 15. If time was not specified, makes the most 
;    recent ndays of plots 
;  orbit - if set, make plots for RHESSI orbit times during time interval specified by 'time'
;  test - if set, don't write to special browser directory
;  stacked - pass through for option to stack plots
;  
;Example:
;  do_goes_rhessi_plots
;  do_goes_rhessi_plots, /stacked
;  do_goes_rhessi_plots, '3-may-2012', ndays=30
;  do_goes_rhessi_plots, ['3-may-2012, '22-may-2012']
;  do_goes_rhessi_plots, ['3-may-2012, '22-may-2012'], /orbit
;  
;Written: Kim Tolbert, 8-May-2012
;Modifications:
; 22-Dec-2016, Kim. Make it do 15 days, not 10
; 20-Aug-2021, Kim. Modified header doc
;
;-

pro do_goes_rhessi_plots, time=t, ndays=ndays, test=test, stacked=stacked, orbit=orbit

browser = ~keyword_set(test)

checkvar, ndays, 15

; If no time specified, do most recent ndays
checkvar, t, anytim(!stime, /date) - (ndays-1)*86400.
ts = anytim(t)

; if time range passed in, convert that to start time (ts) and ndays
if n_elements(ts) eq 2 then begin
  ndays = (ts[1]-ts[0]) / 86400.
  ts = ts[0]
endif

; Make either orbit plots, or 12 or 24 hr plots starting at ts for ndays.  Use /png option in case browser
; is turned off (if test is set), so local .png files will be created.
if keyword_set(orbit) then begin

  trange = ts[0] + [0.,ndays * 86400.]
  ; Get the RHESSI orbit times during the interval trange
  hsi_get_orbit_times,trange, orb_start=os, orb_end=oe, count=count
  if count eq 0 then begin
    message,'No RHESSI orbits in time range ' + format_intervals(trange,/ut), /cont
    return
  endif
  
  ; Make each plot starting at RHESSI orbit start for 6000. seconds to match RHESSI orbit plots
  for i=0,count-1 do goes_rhessi_plot,time=os[i]+[0.,6000.], /png, /rhessi, /filename_time, /orbit, browser=browser

endif else begin
    
  ; For each day specified, make either the 24-hr plots, or 12-hr stacked plots, depending on value of stacked
  for i=0,ndays-1 do begin
    goes_rhessi_plot, time=ts, /png, /rhessi, browser=browser, stacked=stacked
    ts = ts + 86400.
  endfor

endelse

end
