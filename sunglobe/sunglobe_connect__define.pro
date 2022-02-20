;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_CONNECT__DEFINE
;
; Purpose     :	Object graphics for magnetic connection graphic in SUNGLOBE
;
; Category    :	Object graphics, 3D, Planning
;
; Explanation : Called from SUNGLOBE_GET_CONNECT to read in a potential field
;               source surface (PFSS) magnetic model, and estimate where the
;               spacecraft is magnetically connected to the solar surface.
;
; Syntax      :	To initially create:
;                       oConnect = OBJ_NEW('sunglobe_connect', sstate=sstate)
;
;               To retrieve a property value:
;                       oConnect -> GetProperty, property=property
;
;               To set a property value:
;                       oConnect -> SetProperty, property=property
;
;               To build the field-of-view graphic:
;                       oConnect -> build
;
;               To destroy:
;                       OBJ_DESTROY, oConnect
;
; Examples    :	See sunglobe_get_connect.pro, sunglobe_change_date.pro
;
; Keywords    :	The following keyword is required when initializing the object.
;
;               SSTATE  = Widget top-level state structure
;
;               The following keywords pertain to the INIT, GETPROPERTY, and
;               SETPROPERTY methods.
;
;               NLINES     = Target number of magnetic field lines (Default=50)
;
;               GAUSSWIDTH = Angular Gaussian width in degrees of randomly
;                            generated points on the source surface (Default=5)
;
;               WINDSPEED  = Solar wind speed in km/s (Default=450)
;
;               ADJUST     = Adjust for lag time due to solar wind speed
;
;               In addition, any keywords associated with the IDLgrModel object
;               graphics class can also be used.
;
; Common      : Uses @PFSS_DATA_BLOCK to communicate with PFSS software.
;
; Restrictions: Must have SolarSoft PFSS tree loaded.
;
; Calls       :	DATATYPE, PFSS_TIME2FILE, PFSS_RESTORE, WCS_AU, WCS_RSUN,
;               ANYTIM2TAI, UTC2TAI, DIFF_ROT, PFSS_TRACE_FIELD, BOOST_ARRAY
;
; History     :	Version 1, 05-Mar-2018, William Thompson, GSFC
;               Version 2, 10-Apr-2019, WTT, fix pointer free bug
;               Version 3, 25-Mar-2020, WTT, add solar wind time adjustment
;
; Contact     :	WTHOMPSON
;-
;
function sunglobe_connect::init, sstate=sstate, nlines=nlines, $
                                 gausswidth=gausswidth, windspeed=windspeed, $
                                 adjust=adjust, basis=basis, _extra=_extra
;
;  Can't initialize the object without an sstate array.
;
if datatype(sstate) ne 'STC' then begin
    print, 'SSTATE is not a structure'
    return, 0
endif
;
;  Initialize the graphics model containing the connection description.
;
if (self->idlgrmodel::init(_extra=_extra) ne 1) then begin
    print, 'Unable to initiate structure'
    return, 0
endif
;
;  Store the input parameters into the object.
;
self.psstate = ptr_new(sstate)  ;Widget state structure
self.basis = 0                  ;Basis of observer position
self.nlines = 50                ;Target number of field lines
self.gausswidth = 5.0           ;Gaussian width of points on source surface
self.windspeed = 450.0          ;Solar wind speed (km/s)
self.adjust = 0                 ;Adjust for solar wind speed

if n_elements(basis) eq 1 then self.basis = keyword_set(basis)
if n_elements(nlines) eq 1 then self.nlines = nlines
if n_elements(gausswidth) eq 1 then self.gausswidth = gausswidth
if n_elements(windspeed) eq 1 then self.windspeed = windspeed
if n_elements(adjust) eq 1 then self.adjust = adjust
;
;  Build the connection graphics based on the input properties.
;
self->build
;
return, 1
end

;------------------------------------------------------------------------------

pro sunglobe_connect::setproperty, sstate=sstate, basis=basis, nlines=nlines, $
                                   gausswidth=gausswidth, windspeed=windspeed, $
                                   adjust=adjust, recalculate=recalculate, $
                                   _extra=_extra
;
self->idlgrmodel::setproperty, _extra=_extra
for i=0,self.npt-1 do ((*self.polines)[i])->setproperty, _extra=_extra
;
rebuild = 0
if datatype(sstate) eq 'STC' then begin
    ptr_free, self.psstate
    self.psstate = ptr_new(sstate)
    rebuild = 1
endif
if n_elements(basis) eq 1 then begin
    self.basis = basis
    rebuild = 1
endif
if n_elements(nlines) eq 1 then begin
    self.nlines = nlines
    rebuild = 1
endif
if n_elements(gausswidth) eq 1 then begin
    self.gausswidth = gausswidth
    rebuild = 1
endif
if n_elements(windspeed) eq 1 then begin
    self.windspeed = windspeed
    rebuild = 1
endif
if n_elements(adjust) eq 1 then begin
    self.adjust = adjust
    rebuild = 1
endif
;
;  The recalculate property is used to defer rebuilding a hidden connection
;  point until it's unhidden again.
;
if n_elements(recalculate) eq 1 then self.recalculate = recalculate
;
;  Build the connection graphics based on the input properties.
;
if rebuild then self->build
;
end

;------------------------------------------------------------------------------

pro sunglobe_connect::getproperty, sstate=sstate, basis=basis, nlines=nlines, $
                                   gausswidth=gausswidth, windspeed=windspeed, $
                                   adjust=adjust, recalculate=recalculate, $
                                   _ref_extra=_ref_extra
;
((*self.polines)[0])->getproperty, _extra=_ref_extra
self->idlgrmodel::getproperty, _extra=_ref_extra
;
sstate = *self.psstate
recalculate = self.recalculate
basis = self.basis
nlines = self.nlines
gausswidth = self.gausswidth
windspeed = self.windspeed
adjust = self.adjust
;
end

;------------------------------------------------------------------------------

pro sunglobe_connect::build
;
;  Load the PFSS common block.
;
@pfss_data_block
;
target_date = (*self.psstate).target_date
errmsg = ''
distance = 0
;
;  Get the current position.  If BASIS=0, then use SunSPICE.
;
if self.basis eq 0 then begin
    utc = anytim2utc((*self.psstate).target_date, /external)
    test_offset = (*self.psstate).test_offset
    if test_offset ne 0 then utc.year = utc.year + round(test_offset)
    utc = anytim2utc(utc, /ccsds)
;
;  If within the valid range, then get the ephemeris position.
;
    spacecraft = (*self.psstate).spacecraft
    coord = get_sunspice_lonlat(utc, spacecraft, system='carrington', $
                                /degrees, errmsg=errmsg, /au)
    if errmsg eq '' then begin
        distance = coord[0]
        lon0 = coord[1]
        lat0 = coord[2]
    endif
endif
;
;  If BASIS is not zero, or no ephemeris position was found, then use the
;  current orientation.
;
if distance eq 0 then begin
    if errmsg ne '' then xack, [errmsg, $
                                'Unable to get ephemeris information.', $
                                'Using current orientation instead.']
    widget_control, (*self.psstate).wdist, get_value=distance
    widget_control, (*self.psstate).wyaw, get_value=lon0
    widget_control, (*self.psstate).wpitch, get_value=lat0
endif
;
;   Calculate distance from source surface in solar radii.
;
distance = distance*wcs_au()/wcs_rsun() - 2.5
vel = self.windspeed / wcs_rsun(unit='km')
;
;  Find the nearest PFSS file, and load it into the common block.
;
if self.adjust then begin
    tai = utc2tai(target_date) - (distance/vel)
    tdate = tai2utc(tai, /ccsds)
end else tdate = target_date
pfssfile = pfss_time2file(tdate, /ssw_cat, /url)
pfss_restore, pfssfile
;
;  Account for differential rotation, and convert to radians.  Differential
;  rotation will be re-applied in the opposite direction further below.
;
ndays = (anytim2tai(target_date) - utc2tai(now)) / 86400
lon0 = (lon0 - diff_rot(ndays, lat0, /carrington)) * !dtor
lat0 = lat0 * !dtor
;
;  Use the solar wind speed to account for the propagation from the source
;  surface.
;
rot = 2.7e-6                    ;Solar rotation rate (rad/sec)
lon0 = lon0 + distance * rot / vel
;
;  Set up a series of random points on the source surface.
;
tlon = randomu(seed, self.nlines) * 2 * !pi
tlat = (90 - abs(randomn(seed, self.nlines)) * self.gausswidth) * !dtor
;
lon1 = lon0 + atan(-cos(tlat)*sin(tlon-!pi), $
                  sin(tlat)*cos(lat0) - cos(tlat)*sin(lat0)*cos(tlon-!pi))
lat1 = asin(sin(tlat)*sin(lat0) + cos(tlat)*cos(lat0)*cos(tlon-!pi))
;
;  Build the field lines.
;
widget_control, /hourglass
str = replicate(2.5, self.nlines)
stth = 0.5*!pi - lat1
stph = lon1
pfss_trace_field
;
;  Find clusters of footpoints, and calculate the average longitude and
;  latitude of each, along with the standard deviations.
;
lon2 = ptph[0,*]
lat2 = 0.5*!pi - ptth[0,*]
delvarx, lonavg, latavg, lonsig, latsig, percent
nthresh = 0.1 * self.nlines     ;10% threshold
athresh0 = 15 * !dtor           ;15 degree search criterion
athresh = athresh0
;
while n_elements(lon2) gt nthresh do begin
    medlon = median(lon2)
    medlat = median(lat2)
    dist = sqrt((lon2-medlon)^2 + (lat2-medlat)^2)
    w = where(dist lt athresh, complement=wrest, count, ncomplement=nrest)
;
;  Second iteration to improve accuracy.
;
    if count ge nthresh then begin
        avglon = average(lon2[w])
        avglat = average(lat2[w])
        dist = sqrt((lon2-avglon)^2 + (lat2-avglat)^2)
        w = where(dist lt athresh, complement=wrest, count, ncomplement=nrest)
        if count ge nthresh then begin
            boost_array, lonavg, average(lon2[w])
            boost_array, lonsig, stddev(lon2[w])
            boost_array, latavg, average(lat2[w])
            boost_array, latsig, stddev(lat2[w])
            boost_array, percent, round((100. * count) / self.nlines)
        endif
    endif
;
;  Loop to process remaining points.
;
    if count eq 0 then athresh = 2*athresh else begin
        athresh = athresh0
        if nrest gt 0 then begin
            lon2 = lon2[wrest]
            lat2 = lat2[wrest]
        end else delvarx, lon2, lat2
    endelse
endwhile
;
;  Rotate the longitude values based on the latitude
;
lonavg = lonavg + diff_rot(ndays, latavg*!radeg, /carrington) * !dtor
;
;  Store the data in the object structure.
;
self.date = now
self.daterot = target_date
ptr_free, self.lonavg  &  self.lonavg  = ptr_new(lonavg)
ptr_free, self.lonsig  &  self.lonsig  = ptr_new(lonsig)
ptr_free, self.latavg  &  self.latavg  = ptr_new(latavg)
ptr_free, self.latsig  &  self.latsig  = ptr_new(latsig)
ptr_free, self.percent &  self.percent = ptr_new(percent)
;
;  Destroy any previously created connection ovals.
;
for i=0,self.npt-1 do begin
    obj_destroy, (*self.polines)[i]
    obj_destroy, (*self.polabel)[i]
endfor
ptr_free, self.polines
ptr_free, self.polabel
;
;  Create the connection oval graphics objects.
;
self.npt = n_elements(lonavg)
self.polines = ptr_new(objarr(self.npt))
self.polabel = ptr_new(objarr(self.npt))
angle = findgen(361) * !dtor
cosa = cos(angle)
sina = sin(angle)
for i=0,self.npt-1 do begin
    lon3 = lonavg[i] + 2*lonsig[i]*cosa
    lat3 = latavg[i] + 2*latsig[i]*sina
    x = cos(lon3)*cos(lat3)
    y = sin(lon3)*cos(lat3)
    z = sin(lat3)
    ((*self.polines)[i]) = obj_new('IDLgrPolyline', x, y, z, $
                                   color=[255b,0b,0b])
    self->add, ((*self.polines)[i])
;
    lon3 = lonavg[i]
    lat3 = latavg[i]
    location = [cos(lon3)*cos(lat3), sin(lon3)*cos(lat3), sin(lat3)]
    updir = [-cos(lon3)*sin(lat3), -sin(lon3)*sin(lat3), cos(lat3)]
    baseline = [-sin(lon3), cos(lon3), 0]
    char_dimensions = [0.05, 0.05]
    location = location - char_dimensions[0]*baseline - $
               0.5*char_dimensions[1]*updir
    label = ntrim(percent[i]) + '%'
    ((*self.polabel)[i]) = obj_new('IDLgrText', label, location=location, $
                                   updir=updir, baseline=baseline, $
                                   char_dimensions=char_dimensions, $
                                   color=[255b,0b,0b])
    self->add, ((*self.polabel)[i])
endfor
(*self.psstate).hideconnect = 0
self.recalculate = 0
;
widget_control, hourglass=0
end

;------------------------------------------------------------------------------

pro sunglobe_connect__define
struct = {sunglobe_connect, $
          INHERITS IDLgrModel, $
          psstate: ptr_new(), $
          recalculate: 0, $
          basis: 0, $
          nlines: 50, $
          gausswidth: 5.0, $
          windspeed: 450.0, $
          adjust: 0, $
          date: '', $
          daterot: '', $
          npt: 0, $
          lonavg: ptr_new(), $
          lonsig: ptr_new(), $
          latavg: ptr_new(), $
          latsig: ptr_new(), $
          percent: ptr_new(), $
          polines: ptr_new(), $
          polabel: ptr_new()}
end
