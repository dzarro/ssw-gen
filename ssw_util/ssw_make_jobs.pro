pro ssw_make_jobs,t0,t1, hourly=hourly, daily=daily, job_name=job_name, template=template, routine=routine, submit=submit, $
   monthly=monthly, wait_submit=wait_submit, check_submit=check_submit
;
;+
;   Name: ssw_make_jobs
;
;   Purpose: make one or more *.pro files (usually "batch" jobs) with desired cadence/time range - optionally 'submit' them -> ssw_batch
;
;   Input Parameters:
;      t0,t1 - time range
;
;   Keyword Parameters:
;      JOB_NAME - sswidl routine name - will call within each job/pro via JOB_NAME,'START_TIME','END_TIME'
;      template - optional template - desired/verbatim *.pro - will replace strings "START_TIME" & "END_TIME" with derived times - (job_name not required)
;      hourly,daily,monthly (switches, mutually exclusive)  - "cadence" of output jobs
;      submit - submits jobs after creation - if switch, use /ssw/site/bin/ssw_batch
;               -or- explicit ssw_batch scriptname (ex: submit='/ssw/site/bin/ssw_batch_myscript' )
;
;   Side Effects:
;      Generates one or more *.pro files named go_<job_name>_<yyyymmdd_hhmmss>.pro
;      Number of files scales with time range (t0,t1) and  granularity (/daily or /hourly)
;      If submit set or supplied, starts N-jobs (ssw_batch/background) on This machine.
;
;   History:
;      4-sep-2013 - S.L.Freeland - parallel background job helper (ssw_batch)
;      7-sep-2013 - S.L.Freeland - evolved the TEMPLATE and SUBMIT a bit - guess unstated cadence by input time range
;     18-sep-2013 - S.L.Freeland - if /submit (switch) , use $ssw_batch if defined & exists, else defult=/ssw/site/bin/ssw_batch
;     23-jan-2014 - S.L.Freeland - added /MONTHLY cadence
;     30-jul-2014 - S.L.Freeland - add WAIT_SUBMIT param - stagger script submissions by this many SECONDS
;                                  add /CHECK_SUBMIT - show what would be submitted but don't
;
;-

; define time identifires (for future str_replace operations)
startime='START_TIME'
endtime='END_TIME'

;
case 1 of 
   keyword_set(job_name): jname=job_name ; ser supplied
   file_exist(template): begin 
      break_file,template,ll,jobpath,jname,ext
      tempdata=rd_tfile(template)
      ssok=where(strpos(tempdata,startime) ne -1 and strpos(tempdata,endtime) ne -1,tcnt)
      if tcnt eq 0 then begin
         box_message,'TEMPLATE found, but does not include required START_TIME and END_TIME strings... bailing.
         return
      endif 
   endcase
   else: begin 
      box_message,'Need JOB_NAME or TEMPLATE input'
      return
   endcase
endcase

if n_elements(routine) eq 0 then routine=jname

month=keyword_set(monthly)
days=keyword_set(daily)
case 1 of 
   keyword_set(daily): days=1
   keyword_set(hourly): hours=1
   keyword_set(monthly): 
   else: begin
      dts=ssw_deltat(t1,t0,/days)
      daily=dts gt 1
      hours=1-daily
      box_message,'Cadence not specified; deriving from time range'
      box_message,'Cadence= ' + (['hourly','daily'])(daily)
   endcase
endcase

tgrid=timegrid(t0,reltime(t1,hours=hours,days=days or month),hours=hours,days=days,month=month,out='ecs',/trunc)

job_names='go_'+jname + '_' + time2file(tgrid) + '.pro'

nj=n_elements(tgrid)-1

for j=0,nj-1 do begin 
   if n_elements(tempdata) gt 0 then begin 
      ; user supplied template *.pro file
      newdata=tempdata
      newdata[ssok]=str_replace(newdata[ssok],startime,tgrid[j])
      newdata[ssok]=str_replace(newdata[ssok],endtime,tgrid[j+1])
      file_append,job_names[j],newdata,/new
   endif else begin  
      ; user supplied a job_name/routine name - make the 2-liner batch job for each time range
      file_append,job_names[j],arr2str([job_name,"'"+tgrid[j]+"'","'"+tgrid[j+1]+"'"]),/new
      file_append,job_names[j],'end'
   endelse
endfor

if keyword_set(submit) then begin 
   check_submit=keyword_set(check_submit)
   if n_elements(wait_submit) eq 0 then wait_submit=0 ; pause between submissions
   sswbatch=get_logenv('$ssw_batch') ; optional local environmental?
   case 1 of
      file_exist(submit):  batch=submit ; user supplied
      file_exist(sswbatch): batch=sswbatch ; $ssw_batch defined - use that
      else: batch='/ssw/site/bin/ssw_batch'
   endcase
   box_message,'Using batch script> ' + batch

   for j=0,nj-1 do begin
      cmd=batch + ' ' + job_names[j] + ' ' + job_names[j]+'.log &'
      box_message,cmd
      if check_submit then box_message,'check_submit, not really submitting' else spawn,cmd
      if wait_submit gt 0 then begin 
         box_message,'Pausing ' + strtrim(wait_submit,2) + ' seconds between submissions
         wait,wait_submit
      endif
   endfor
endif

return
end
 



