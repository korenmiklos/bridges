clear
set more off
capture log close
log using results/pooled_event_study.log, text replace

do create_variables  `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' 

forval r=1/12 {
	gen river_mile_`r' = river_mile*(river=="``r''")
}

xtpoisson total treatment* river_mile_*, i(river_year) fe
*test (treatment70+treatment80+treatment80)/3==(treatment110+treatment120+treatment130)/3
gen po_hat = .
gen se = .
forval t=70/130 {
	replace po_hat = _b[treatment`t'] if event_time==`t'
	replace se = _se[treatment`t'] if event_time==`t'
}
replace event_time = event_time - offset
label var po_hat "Post office count (log)"
label var event_time "Years since bridge"

gen upper = po_hat + 1.96*se
gen lower = po_hat - 1.96*se
tw (area  upper lower event_time, base(0.3 0.3) sort astyle( ci plotregion)) (line po_hat event_time, sort),  scheme(s2color) legend(order(1 "95% confidence interval" 3 "Post office count (log)"))
graph save results/pooled_event_study.gph, replace


capture log close
