pro testpool,n
; this snippet is "designed" to throw error for N>10 - testing ssw_make_jobs_pool.pro logistics/error response
arr=indgen(10)
print,arr[n]
return
end
