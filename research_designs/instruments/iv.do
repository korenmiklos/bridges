set more off
set matsize 5000, permanently
local RIVERS arkansas colorado columbia connecticut delaware hudson ohio red snake tennessee missouri  mississippi
tempfile rivers
clear
save `rivers', replace emptyok

foreach river in `RIVERS' {
	insheet using output/`river'.csv, clear
	gen location = _n
	gen str river = "`river'"
	append using `rivers'
	save `rivers', replace
}

egen river_number = group(river)
su river_number
local N = r(max)

forval n=1/`N' {
	gen river_mile_`n' = river_mile*(river_number==`n')
	gen river_mile_sq_`n' = river_mile^2*(river_number==`n')
}

gen segment = int(river_mile*1.6/30)
egen cluster = group(river segment)

gen log_post_office_count = log(post_office_count)
gen byte has_bridge = bridges>0 & !missing(bridges)

tsset river_number location

reg bridges river_mile_* water_covered_area crossing_points, robust
test water_covered_area crossing_points

label var log_post_office_count "Number of post offices (log)"
label var bridges "Number of bridges"
label var has_bridge "Segment has a bridge (dummy)"
label var water_covered_area "Width of the river"
label var crossing_points "Number of predicted crossing points"

reg bridges water_covered_area L.water_covered_area F.water_covered_area crossing_points F.crossing_points L.crossing_points river_mile_*, robust
outreg2 using output/bridges_first_stage.tex, tex(frag) replace label

reg has_bridge water_covered_area L.water_covered_area F.water_covered_area crossing_points F.crossing_points L.crossing_points river_mile_*, robust
outreg2 using output/bridges_first_stage, tex(frag) append label
 
ivregress 2sls log_post_office_count (bridges = water_covered_area L.water_covered_area F.water_covered_area crossing_points F.crossing_points L.crossing_points) river_mile_*, robust
outreg2 using output/bridges_iv.tex, tex(frag) replace label

ivregress 2sls log_post_office_count (has_bridge = water_covered_area L.water_covered_area F.water_covered_area crossing_points F.crossing_points L.crossing_points) river_mile_*, robust
outreg2 using output/bridges_iv.tex, tex(frag) append label

/*
Instrumental variables (2SLS) regression               Number of obs =     907
                                                       F( 23,   399) =   27.03
                                                       Prob > F      =  0.0000
                                                       R-squared     =  0.4739
                                                       Root MSE      =  .56372

                                  (Std. Err. adjusted for 400 clusters in cluster)
----------------------------------------------------------------------------------
                 |               Robust
log_post_offic~t |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-----------------+----------------------------------------------------------------
         bridges |    .136285   .2181477     0.62   0.533    -.2925776    .5651476

*/
