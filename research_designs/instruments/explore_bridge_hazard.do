clear all

local window 5
local first_bridge 1780
local outcome bridge

do read_data_by_mile

bysort river river_mile: gen period = _n

gen calendar_time = first_`outcome'
gen byte event = !missing(calendar_time)
* right censoring: event has not happened by 2016
replace calendar_time = 2016 if !event

* FIXME: use exploration data to find first possible bridging date for each river
gen at_risk_time = `first_bridge'

stset calendar_time, origin(time at_risk_time) failure(event)

gen width_category = river_width
recode width_category min/2000=0 2000/max=1
tab width_category event

egen river_code = group(river)
su river_code
local rivers = r(max)
forval r=1/`rivers' {
	foreach X of var river_mile {
		gen `X'_`r' = (river_code==`r')*`X'
	}
}

su width_category
local J = r(max)

tempfile st0 st1 st2 st3
forval i=0/`J' {
	stcox i.river_code river_mile_* if width_category==`i'
	stcurve, survival outfile(`st`i'', replace)
}
forval i=0/`J' {
	use `st`i'', clear
	collapse (first) surv1, by(_t)
	replace _t = _t+`first_bridge'
	ren surv1 survival_`i'
	save `st`i'', replace
}

use `st0'
forval i=1/`J' {
	merge 1:1 _t using `st`i''
	drop _m
}

* add 1780 with survival=1
expand (_n==1)+1
replace _t = `first_bridge' in 1
sort _t
forval i=0/`J' {
	replace survival_`i' = 1 in 1
	replace survival_`i' = survival_`i'[_n-1] if missing(survival_`i')
	* hazard in percent per year
	gen hazard_`i' = 100*(ln(survival_`i'[_n-`window'])-ln(survival_`i'[_n+`window']))/(_t[_n+`window']-_t[_n-`window'])
}

line hazard_* _t if _t<1910 & _t>1800, sort legend(order(1 "Narrow" 2 "Wide")) xtitle(Year) ytitle("Hazard of first `outcome' emerging, %/year/mile")
graph export output/emergence_of_`outcome's.png, width(800) replace
save output/`outcome'_hazards, replace
