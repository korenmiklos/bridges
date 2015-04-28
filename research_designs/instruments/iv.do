set more off
set matsize 5000, permanently
local RIVERS arkansas colorado columbia connecticut delaware hudson ohio red snake tennessee missouri  mississippi
tempfile rivers
clear
save `rivers', replace emptyok

* historical crossing points at following rivermiles
local x_connecticut 68 86 144 197
local x_hudson 42 67 93 154 220
local x_delaware 128 139 146
local x_tennessee 190 369 400
local x_ohio 897 810 626 586 494
* from 1800 map
local x_mississippi 64 313 533 658 881 923 
local x_missouri 130 353 600 770 1020 1179 1354 1575 2095 2260
local x_arkansas 112 312 364 757

foreach river in `RIVERS' {
	insheet using output/`river'.csv, clear
	gen location = _n
	gen str river = "`river'"
	
	* distance to nearest historical crossing
	local crossings : word count `x_`river''
	forval i=1/`crossings' {
		local crossing : word `i' of `x_`river''
		gen distance_`i' = abs(river_mile-`crossing')
	}
	capture egen closest_crossing = rmin(distance_*)
	capture drop distance_*
	
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

* a cycle of potential bridges every 30 miles
gen cycle = cos(closest_crossing/30*2*c(pi))
gen within_10mi = closest_crossing<=10

local instruments closest_crossing F.closest_crossing L.closest_crossing water_covered_area L.water_covered_area F.water_covered_area

reg bridges `instruments' river_mile_*, robust
predict predicted_bridges
outreg2 using output/bridges_first_stage.tex, tex(frag) replace label

reg has_bridge `instruments' river_mile_*, robust
outreg2 using output/bridges_first_stage, tex(frag) append label
 
ivregress 2sls log_post_office_count (bridges = `instruments') river_mile_*, robust
outreg2 using output/bridges_iv.tex, tex(frag) replace label

ivregress 2sls log_post_office_count (has_bridge = `instruments') river_mile_*, robust
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
