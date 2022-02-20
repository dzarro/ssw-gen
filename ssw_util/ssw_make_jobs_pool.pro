pro ssw_make_jobs_pool,command, pool_parent, njobs=njobs, do_next=do_next, $
   times=times, start_times, stop_times, no_submit=no_submit, wait_submit=wait_submit, $
   batch_script=batch_script, loud=loud, init_pool=init_pool, clobber=clobber
; 
;+
;   Name: ssw_make_jobs_pool
;
;   Purpose: generate/run parallel sswidl jobs; param/job pool&Q management ; optionally, iterate until pool empty
;
;   Input Parameters:
;      command - routine name, assumed to process one PARAM from pool , PARAM may be a time range per TIMES switch
;      pool_parent  - top path for This set of PARAMS
;
;   Keyword Parameters:
;      njobs - #of jobs to start with - defines # of parallel jobs to run
;      do_next (switch) if set, append code to run The Next parameter in pool (maintains NJOBS in parallel until POOL empty)
;      init_pool - if vector, populate POOL with this set of stuff (PARAMS or JOBS) - e.g. vector of ALL desired params to eventually process
;      times (switch) - special case where pool elements are comma delimited STARTTIME,STOPTIME string vectors
;      no_submit (switch) - if set, dont actually submit any jobs (usually just INIT pool with INIT_POOL vector)
;      wait_submit - wait between spawning jobs, in seconds
;
;   History:
;      1-aug-2016 - S.L.Freeland - expands on ssw_make_jobs.pro & ssw_iris_obspool_makejobs.pro concepts
;     15-sep-2016 - S.L.Freeland - prepend error handler, add <pool_parent>/error for destination for params/jobs error-out.
;     18-sep-2016 - S.L.Freeland - enable the /DO_NEXT switch (submit Next job in pool); maintain NJOBS until pool empty
;     27-jan-2017 - S.L.Freeland - enable WAIT_SUBMIT keyword function
;
;   Side Effects:
;      First call with INIT_POOL=<params> will create and populate directory tree;  optionally kick off 1st NJOBS out of #INIT_POOL
;        <pool_parent>/requested - all requested PARAMs (via file-names)
;        <pool_parent>/current   - [0:NJOBS-1] subset of above (these are in-progress subset)
;        <pool_parent>/finished - completed PARAMS
;        <pool_parent>/error - subset of PARAMS which caused error-out
;        <pool_parent>/jobs - *.pro files generated/run by This app.
;        <pool_parent>/logs - 1:1 above, execution logs for each *.pro via $ssw_batch_script output
;
;   TODO:
;      need a little user guide w/examples...
;-

if n_params() lt 2 then begin 
   box_message,'need at least a command string & pool_parent'
   return ; EARLY EXIT on < 2 params
endif

if n_elements(njobs) eq 0 then njobs=1

; define the Five parallel directories:
req=concat_dir(pool_parent,'requested') ; these are pending PARAMS or JOBS
cur=concat_dir(pool_parent,'current')   ; these are running/in-progress JOBS
fin=concat_dir(pool_parent,'finished')  ; these PARAMS or JOBS ran to completion
jobs=concat_dir(pool_parent,'jobs')     ; the *.pro created by this routine
logs=concat_dir(pool_parent,'logs')     ; the IDL job logfiles (ssw_batch output)
err=concat_dir(pool_parent,'error')

if ~file_exist(logs) then mk_dir,[req,cur,fin,jobs,logs,err]

if keyword_set(init_pool) then begin 
   for i=0,n_elements(init_pool) -1  do file_append,concat_dir(req,strtrim(init_pool[i],2)),'',/new
endif

loud=keyword_set(loud)
ssw_batch_script=get_logenv('ssw_batch_script') ; user/site defined? ($SSW/site/setup/IDL_STARTUP for example)?
ont_batch_script=concat_dir('$SSW_ONTOLOGY','binaries/ssw_batch_64')
case 1 of 
   keyword_set(batch_script): ; user supplied via keyword
   file_exist(ssw_batch_script): ssw_batch=ssw_batch_script
   file_exist(ont_batch_script): ssw_batch=ont_batch_script 
   else: begin
      box_message,'Using original $SSW/gen/bin/ssw_batch; you may want verify OK for your app'
      batch_script=concat_dir('$SSW_BIN','ssw_batch')
   endcase
endcase
   
requested=file_search(req,'') ; check POOL for pending/requested stuff
requested=requested[sort(requested)]
no_submit=keyword_set(no_submit)

if requested[0] eq '' then begin ; exit if nothing to do
   mess=(['No jobs pending, returning...','/NO_SUBMIT set; returning'])
   box_message,mess
endif else begin 
   need=last_nelem(requested,njobs)
   file_move,need,cur ; this removes them from contention
   nj=n_elements(need)
   onames=ssw_strsplit(need,'/',/tail)
   cname=strtrim(ssw_strsplit(command+",",",",/head),2)
   cname=cname[0]
   jname=cname+'_'+onames
   jnames=jname+'.pro'
   lnames=jname+'.log'
   pros=concat_dir(jobs,jnames)
   logs=concat_dir(logs,lnames)   
   cmds=cname+",'" +onames+"'"

   bcmds=ssw_batch + ' ' + pros + ' ' + logs + ' &'
   for j=0,nj-1 do begin 
     file_append,pros[j],'catch,error_status',/new
     file_append,pros[j],'if error_status eq 0 then '+ cmds[j]
     file_append,pros[j],"outdir=(['" + fin + "','" + err+"'])(error_status ne 0)"
     file_append,pros[j],'catch,/cancel'
     cdone=concat_dir(cur,onames[j])
     file_append,pros[j],'file_move,"'+cdone+'",outdir'
     if keyword_set(do_next) then begin ; add code to call This routine to process Next pool element
        ncommand="ssw_make_jobs_pool,njobs=1,do_next=1,'" + command  + "','" + pool_parent+ "'"
        file_append,pros[j], ncommand
     endif
     file_append,pros[j],'end' 
     print,bcmds[j]
     spawn,bcmds[j]
     if keyword_set(wait_submit) ne 0 then begin 
        box_message,'Pausing WAIT_SUBMIT seconds= ' + strtrim(wait_submit,2) + ' between job submit....'
        wait,wait_submit
     endif

   endfor
endelse

return
end
