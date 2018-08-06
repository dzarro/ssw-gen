
pro get_bridge_setup, bridge_direc=bridge_direc, mac_os=mac_os, linux_os=linux_os, $
                    idl_ver=idl_ver, py_ver=py_ver, py_dist=py_dist

;+
; Purpose:
;    - Spit back the necessary 


; Comment: The IDL bridges are apparently very version-dependent.
;
; Therefore:
;    Needed: 'database' of successful and failed setups by:
;
; Mac OS version
; Linux version
; IDL version
; Python version
; Python distribution source (anaconda, homebrew, whatever)
;
; Method:
;    You pass the above option parameters, and the routine returns one of:
;
;       1. setup script as string array, if that set of options has been successfully used
;       2. 'failed' with string arr explanation/error message/etc
;       3. 'not tried'
;
; The 'crowd' slowly builds and maintains this going forward.
;-

; If no parms passed, then print out the setup commannds for both
; bridge directions for the Mac OS and Linux cases that I have tested successfully:

out_default = $
   [ $
    '', $
    '', $
    'Mac OS setup:', $
    '=============', $
    '', $
    'setenv IDL_DIR /Applications/exelis/idl85', $
    'setenv PYTHONHOME $HOME/anaconda2', $
    'setenv PYTHONPATH $IDL_DIR/lib/bridges:$SSW/gen/python/bridge', $
    'setenv PYTHONSTARTUP $SSW/gen/python/bridge/startup.py', $
    'alias pyssw $PYTHONHOME/bin/python', $
    '', $
    'where the script "startup.py" consists of the following:', $
    '', $
    '   # PYTHON start-up file. Define PYTHONSTARTUP to point to this file', $
    '', $
    '   print("Running Python-IDL bridge startup...")', $
    '   try:', $
    '       import bridge', $
    '       IDL=bridge.startup()', $
    '   except:', $
    '       from idlpy import *', $
    '', $
    '', $   
    'Linux setup:', $
    '============', $
    '', $
    'setenv IDL_DIR /usr/local/exelis/idl85', $
    'setenv PYTHONHOME $HOME/anaconda2', $
    'setenv PATH ${PYTHONHOME}/bin:${PATH}', $
    'setenv PYTHONPATH $IDL_DIR/bin/bin.linux.x86_64:$IDL_DIR/lib/bridges:$SSW/gen/python/bridge', $
    'setenv PYTHONSTARTUP $SSW/gen/python/bridge/startup.py', $
    'setenv LD_LIBRARY_PATH ${PYTHONHOME}/lib:$IDL_DIR/bin/bin.linux.x86_64', $
    'alias pyssw $PYTHONHOME/bin/python', $
    '', $
    ''  $
   ]

if n_params() eq 0 then begin
   prstr, out_default, /nomore
endif

end
