;+
; Project     : HESSI
;                  
; Name        : SOLAR_DROT
;               
; Purpose     : Return solar differential rotation period as function of latitude
;                             
; Category    : utility
;               
; Syntax      : IDL> days=solar_drot(latitude)
; 
; Inputs      : LATITUDE = solar latitude between 0 and 90
;                                        
; Outputs     : DAYS = rotation periodl (def = Synodic)
;
; Keywords    : See DIFF_ROT
;                   
; History     : 17-Apr-2003, Zarro (EER/GSFC)
;               17-Feb-2019, Zarro (ADNET/GSFC) - written
;
; Contact     : dzarro@solar.stanford.edu
;-    

function solar_drot,lat,_extra=extra
if is_number(lat) then dlat= (0. > abs(lat[0]) < 90.) else dlat=0.
days=findgen(50)
deg=diff_rot(days,dlat,/synodic,_extra=extra)
value=find_value(days,deg,360.)
return,value
end
