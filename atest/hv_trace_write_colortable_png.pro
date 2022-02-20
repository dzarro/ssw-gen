;
; 9 October - WRITE out TRACE color tables
;
;
PRO HV_TRACE_WRITE_COLORTABLE_PNG,dir = dir, sunpy=sunpy, rgb=rgb, nowrite=nowrite, measurements=measurements
;
  if not keyword_set(dir) then dir = ''
  inst = ['TRACE']

; Measurement '-1000' is the whitelight measurement, noted as 'WL'
; in the FITS header
  if not(keyword_set(measurements)) then begin
     measurements = [171, 195, 284, 1216, 1550, 1600, 1700, -1000]
  endif

  dsave=!d.name
  
;  set_plot,'z'
  for j = 0,n_elements(measurements)-1 do begin
     a = findgen(1,256)
     if measurements[j] ne -1000 then begin
        ; all wave bands except white light
        trace_colors,measurements[j],r,g,b
        mname = trim(measurements[j])

     ; Write out the values of the RGB stream as numbers for SunPy"
        if keyword_set(sunpy) then begin
           tbl_name = strarr(3)
           tbl_name[0] = 'r'
           tbl_name[1] = 'g'
           tbl_name[2] = 'b'
           for i = 0,2 do begin
              app = '['
              if i eq 0 then tbl = r
              if i eq 1 then tbl = g
              if i eq 2 then tbl = b
              for k = 0, 255 do begin
                 if k ne 255 then begin
                    app = app + trim(nint(tbl[k])) + ', '
                 endif else begin
                    app = app + trim(nint(tbl[k]))
                 endelse
              endfor
              app = app + '], dtype=np.uint8)'
              app = 'trace_' + mname + '_' + tbl_name[i] + ' = np.array(' + app
              print, app
           endfor
           print,' '
        endif
     endif else begin
        ; take care of the white light measurement
        loadct, 0, rgb_table=rgb_table
        r = reform(rgb_table[*, 0])
        g = reform(rgb_table[*, 1])
        b = reform(rgb_table[*, 2])
        mname = 'WL'
     endelse
     ; write a color table for the given measurement name "mname"
     if not(keyword_set(nowrite)) then begin
        write_png,dir + mname + '_colortable.png', a, reverse(r), reverse(g),reverse(b)
     endif
     rgb = intarr(3, 256)
     rgb[0, *] = r[*]
     rgb[1, *] = g[*]
     rgb[2, *] = b[*]
  endfor
  set_plot,!d.name

  return
end
