tempfile rivers
save `rivers', replace emptyok
foreach river in `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' {
	di "`1'"
	insheet using data/`river'.csv, clear
	gen bridge = _n
	gen str river = "`river'"
	reshape long left_ right_, i(bridge) j(year)
	ren left_ left
	ren right_ right
	append using `rivers'
	save `rivers', replace
}
egen river_bridge = group(river bridge)
egen river_year = group(river year)
gen segment = int(river_mile/10)
egen river_segment = group(river segment)

tsset river_bridge year

gen total = left+right

gen start_decade = int(start/10)*10
local dec 3
local window `dec'0

local sample_window 40
local latest 1900

* for ease of reading, introduce a round offset for event time
scalar offset = 100
gen event_time = year-start_decade+offset
* also keep control regions
keep if abs(event_time-offset)<=`sample_window' | missing(start)
* only use 19th century, when post offices are relevant
keep if year<=`latest' & (start_decade<=`latest' | missing(start))

replace event_time = -`window'+offset if event_time<-`window'+offset
replace event_time = `window'+offset if event_time>`window'+offset & !missing(event_time)

forval t = 7/13 {
	gen byte treatment`t'0 = (event_time==`t'0)
}

gen byte no_bridge = missing(start)
gen byte before = year<start & !no_bridge
gen byte after = year>=start

egen left_before = sum(cond(!after,left,0)), by(river_bridge)
egen right_before = sum(cond(!after,right,0)), by(river_bridge)

gen small = cond(left_before<right_before,left,right)
gen large = cond(left_before<right_before,right,left)
gen log_small = ln(small)
gen log_large = ln(large)

gen river_mile_sq = river_mile^2

gen small_share = small/total
replace small_share=0 if total==0
* if total number of post offices is poisson, the variance is sqrt of mean
gen scaled_difference = cond(left_before<right_before,right-left,left-right)/sqrt(total)

gen deviation = 0.5-small_share
tsset river_bridge year
gen change = deviation-L10.deviation
gen lag_deviation = L10.deviation
