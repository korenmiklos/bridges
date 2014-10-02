set more off
set matsize 5000, permanently
local RIVERS arkansas colorado columbia connecticut delaware hudson  missouri ohio red snake tennessee

tempfile rivers
clear
save `rivers', replace emptyok

foreach river in `RIVERS' {
	insheet using data/`river'.csv, clear
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

reg bridges river_mile_* water_covered_area, cluster(cluster) 
ivreg log_post_office_count (bridges = water_covered_area) river_mile_*,  cluster(cluster) 

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
