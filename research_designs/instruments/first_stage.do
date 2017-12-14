clear all

local first_bridge 1780
local first_steel_bridge 1880
local width 500
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

stcox i.river_code river_mile_* after_steel_* wider`width'm*, nohr
test wider`width'm wider`width'mXafter_steel
/*
        wider500m |  -.0408966   .0850278    -0.48   0.631     -.207548    .1257548
wider500mXafter~l |    .140974   .1235395     1.14   0.254     -.101159    .3831069
-----------------------------------------------------------------------------------

. test wider`width'm wider`width'mXafter_steel

 ( 1)  wider500m = 0
 ( 2)  wider500mXafter_steel = 0

           chi2(  2) =    1.40
         Prob > chi2 =    0.4961

*/
predict hazard_ratio, hr
gen ln_hazard_ratio = ln(hazard_ratio)
