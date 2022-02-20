function ssw_bin_path, module, parent=parent, found=found, ontology=ontology, path_only=path_only
;
;+
;   Name: ssw_bin_path
;
;   Purpose: construct/check OS_ARCH (!version) branch for specified module for "sytem-indepent" *.pro wrappers
;
;   Input Parameters:
;      module - name of verbatim (e.g. with extension if expected) program/binary etc of interest
;
;   Output:
;      function returns OS/ARCH dependent path to 'module' (use with FOUND state to spawn or bail)
;      
;   Keyword Parameters:
;      parent - top of binaries tree ; assumes SSW SOP organization <parent>/<OS_ARCH>/<binaries> - def=$SSW_BINARES/exe/
;      ontology (switch) - if set, set default <parent> to $SSW_ONTOLOGY/binaries 
;      found (output) - =1 if module found 
;
;   History:
;      23-oct-2012 - S.L.Freeland - less wordy/search recast of ssw_bin.pro (by freeland...)
;
;   Calling Examples:
;      IDL> mp=ssw_bin_path('mpeg_encode',found=found) ; default <parent>
;      IDL> help,mp,found
;         MP              STRING    = '/net/solarsan/Volumes/venus/ssw/packages/binaries/exe/linux_x86/mpeg_encode'
;         FOUND           BYTE      =    1
;
;      IDL> ic=ssw_bin_path('imcopy',/ontology,found=found)
;      IDL> help,ic,found
;        IC              STRING    = '/net/solarsan/Volumes/venus/ssw/vobs/ontology/binaries/linux_x86/imcopy'
;        FOUND           BYTE      =    1
;-

if n_elements(module) eq 0 then module='' ; will just return path

case 1 of
   data_chk(parent,/string) : ; user supplied
   keyword_set(ontology): parent=concat_dir('$SSW_ONTOLOGY','binaries')
   else: parent=concat_dir('$SSW_BINARIES','exe') ; historical default
endcase

osarc_sub=!version.os + '_' + !version.arch
osarc_path=concat_dir(parent,osarc_sub) + '/'
retval=concat_dir(osarc_path,module)
found=file_exist(retval)
retval=([retval,osarc_path])(keyword_set(path_only))
return,retval
end


