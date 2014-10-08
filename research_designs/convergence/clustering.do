clear
set more off
capture log close
log using results/clustering.log, text replace

do create_variables  `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' 

drop left_* right_* left right total
ren center count1
ren ring count0
reshape long count, i(river bridge year) j(center)

forval r=1/12 {
	foreach X of var river_mile lon lat {
		gen `X'_`r' = `X'*(river=="``r''")
	}
}
foreach X of var treatment* {
	gen center_`X' = center*`X'
}

egen river_center_year = group(river center year)

xtpoisson count center center_* treatment* river_mile_* lon_* lat_*, i(river_center_year) fe
*test (treatment70+treatment80+treatment80)/3==(treatment110+treatment120+treatment130)/3
gen po_hat_ring = .
gen po_hat_center = .
forval t=70/130 {
	replace po_hat_ring = _b[treatment`t'] if event_time==`t'
	replace po_hat_center = _b[treatment`t']+_b[center_treatment`t'] if event_time==`t'
}
replace event_time = event_time - offset
label var po_hat_ring "5-10km from bridge"
label var po_hat_center "0-5km from bridge"
label var event_time "Years since bridge"

tw (line po_hat_* event_time, sort),  ytitle("Post office count (log)") scheme(s2color)
graph save results/clustering.gph, replace


capture log close
