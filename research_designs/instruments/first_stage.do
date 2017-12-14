clear all
tempfile bridges rivers postoffices
save `bridges', replace emptyok
save `rivers', replace emptyok
save `postoffices', replace emptyok

local resolution 1
local first_bridge 1780
local first_steel_bridge 1880
local width 500

foreach river in arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi {
	di "`river'"
	insheet using input/rivers/`river'/bridges.csv, clear
	gen bridge = _n
	gen str river = "`river'"
	
	capture drop duplicates
	collapse (min) start, by(river river_mile)

	append using `bridges'
	save `bridges', replace

	insheet using temp/post_offices/`river'.csv, clear
	replace river_mile = int(river_mile)
	gen str river = "`river'"
	
	capture drop duplicates
	collapse (min) first_post_office=po_from, by(river river_mile)

	append using `postoffices'
	save `postoffices', replace

	insheet using output/`river'.csv, clear
	gen bridge = _n
	gen str river = "`river'"
	
	capture drop duplicates
	replace river_width = . if river_width==0
	collapse (min) river_width, by(river river_mile)

	append using `rivers'
	save `rivers', replace

}

merge 1:1 river river_mile using "`bridges'"
drop if missing(river_width)
drop _m

merge 1:1 river river_mile using "`postoffices'"
drop _m

replace river_mile = `resolution'*int(river_mile/`resolution')
gen ln_river_width = ln(river_width )

/*
* test reduced form
gen first_bridge = start
replace start = first_post_office
*/
* bridging technology changes in 1880, duplicate these segments for hazard analysis
gen byte late = start>`first_steel_bridge' | missing(start)
expand late+1
bysort river river_mile: gen period = _n

gen calendar_time = start
replace calendar_time = `first_steel_bridge' if period==1 & late==1
replace calendar_time = 2016 if missing(calendar_time)

* FIXME: use exploration data to find first possible bridging date for each river
gen at_risk_time = `first_bridge'
gen byte event = !missing(start) & (period==2|late==0)
gen after_steel = period==2

* for late period, hazard will be different
replace at_risk_time = `first_steel_bridge' if after_steel

stset calendar_time, origin(time at_risk_time) failure(event)

foreach i in 500 1000 2000 {
	gen wider`i'm = river_width>`i'
	gen wider`i'mXafter_steel = wider`i'm*after_steel
}
egen river_code = group(river)
su river_code
local rivers = r(max)
forval r=1/`rivers' {
	foreach X of var river_mile after_steel {
		gen `X'_`r' = (river_code==`r')*`X'
	}
}

stcox i.river_code river_mile_* after_steel_* wider`width'm*, nohr
test wider`width'm wider`width'mXafter_steel
/*
        wider500m |  -.6671109   .2566069    -2.60   0.009    -1.170051   -.1641707
wider500mXafter~l |   .7986306   .2801724     2.85   0.004     .2495028    1.347758
-----------------------------------------------------------------------------------

. test wider`width'm wider`width'mXafter_steel

 ( 1)  wider500m = 0
 ( 2)  wider500mXafter_steel = 0

           chi2(  2) =    8.15
         Prob > chi2 =    0.0170

*/
predict hazard_ratio, hr
gen ln_hazard_ratio = ln(hazard_ratio)
