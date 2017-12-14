clear all
tempfile bridges rivers postoffices
save `bridges', replace emptyok
save `rivers', replace emptyok
save `postoffices', replace emptyok

local resolution 1

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

bysort river river_mile: gen period = _n

* REDUCED FORM
replace start = first_post_office
gen calendar_time = start
replace calendar_time = 2016 if missing(calendar_time)

* FIXME: use exploration data to find first possible bridging date for each river
local first_bridge 1780
gen at_risk_time = `first_bridge'
gen byte event = !missing(start)

stset calendar_time, origin(time at_risk_time) failure(event)

gen width_category = river_width
recode width_category min/2000=0 2000/max=1
tab width_category event

egen river_code = group(river)
su river_code
local rivers = r(max)

tempfile st0 st1 st2
forval i=0/1 {
	stcox i.river_code if width_category==`i'
	stcurve, survival outfile(`st`i'', replace)
}
forval i=0/1 {
	use `st`i'', clear
	collapse (first) surv1, by(_t)
	replace _t = _t+`first_bridge'
	ren surv1 survival_`i'
	save `st`i'', replace
}

use `st0'
forval i=1/1 {
	merge 1:1 _t using `st`i''
	drop _m
}

* add 1780 with survival=1
expand (_n==1)+1
replace _t = `first_bridge' in 1
sort _t
forval i=0/1 {
	replace survival_`i' = 1 in 1
	replace survival_`i' = survival_`i'[_n-1] if missing(survival_`i')
	gen hazard_`i' = 100*(ln(survival_`i'[_n-10])-ln(survival_`i'[_n]))/(_t-_t[_n-1])
}
label var survival_0 "0-2000m"
label var survival_1 ">2000m" 

line survival_* _t, sort
graph export output/emergence_of_post_offices.png, width(800) replace
save output/post_office_hazards, replace
