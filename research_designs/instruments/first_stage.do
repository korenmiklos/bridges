clear all

local first_bridge 1780
local first_steel_bridge 1880
local width 500
* corresponds to half life of 10 miles
local tau 0.069
local outcome post_office

do read_data_by_mile

/*
* test reduced form
gen first_bridge = start
replace start = first_post_office
*/
* bridging technology changes in 1880, duplicate these segments for hazard analysis
gen calendar_time = first_`outcome'
gen byte late = calendar_time>`first_steel_bridge' | missing(calendar_time)
expand late+1
bysort river river_mile: gen period = _n

replace calendar_time = `first_steel_bridge' if period==1 & late==1
gen byte event = !missing(first_`outcome') & (period==2|late==0)
replace calendar_time = 2016 if missing(calendar_time)

* FIXME: use exploration data to find first possible bridging date for each river
gen at_risk_time = `first_bridge'
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


gen exp_to_crossing = exp(-`tau'*closest_crossing)

stcox i.river_code river_mile_* after_steel_* exp_to_crossing  wider`width'm*, nohr
test exp_to_crossing wider`width'm wider`width'mXafter_steel
/*
  exp_to_crossing |   .7603109   .1985023     3.83   0.000     .3712536    1.149368
        wider500m |  -.6043958   .2588313    -2.34   0.020    -1.111696   -.0970958
wider500mXafter~l |   .7697854   .2823757     2.73   0.006     .2163392    1.323232
-----------------------------------------------------------------------------------

. test exp_to_crossing wider`width'm wider`width'mXafter_steel

 ( 1)  exp_to_crossing = 0
 ( 2)  wider500m = 0
 ( 3)  wider500mXafter_steel = 0

           chi2(  3) =   22.56
         Prob > chi2 =    0.0000
*/

if ("`outcome'"=="bridge") {
	predict xb, xb
	predict hazard_ratio, hr
	predict survival, basesurv
	gen ln_hazard_ratio = ln(hazard_ratio)
	save temp/bridge_hazard_change, replace
}
if ("`outcome'"=="post_office") {
	merge 1:1 river river_mile period using temp/bridge_hazard_change
	stcox i.river_code river_mile_* after_steel_* xb, nohr
	test xb
}

/*
            xb |   .1759664   .0952562     1.85   0.065    -.0107324    .3626651
--------------------------------------------------------------------------------
.         test xb

 ( 1)  xb = 0

           chi2(  1) =    3.41
         Prob > chi2 =    0.0647
*/
