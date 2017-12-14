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

stcox i.river_code river_mile_* after_steel_* exp_to_crossing  wider`width'm*, nohr vce(cluster river_segment)
test exp_to_crossing wider`width'm wider`width'mXafter_steel
/*
  exp_to_crossing |   .7603109   .2603889     2.92   0.004      .249958    1.270664
        wider500m |  -.6043958   .2735927    -2.21   0.027    -1.140628   -.0681639
wider500mXafter~l |   .7697854   .2735517     2.81   0.005      .233634    1.305937
-----------------------------------------------------------------------------------

. test exp_to_crossing wider`width'm wider`width'mXafter_steel

 ( 1)  exp_to_crossing = 0
 ( 2)  wider500m = 0
 ( 3)  wider500mXafter_steel = 0

           chi2(  3) =   16.00
         Prob > chi2 =    0.0011
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
	stcox i.river_code river_mile_* after_steel_* xb, nohr vce(cluster river_segment)
	test xb
}

/*
            xb |   .1759664   .0930434     1.89   0.059    -.0063953    .3583281
--------------------------------------------------------------------------------
.         test xb

 ( 1)  xb = 0

           chi2(  1) =    3.58
         Prob > chi2 =    0.0586
*/
