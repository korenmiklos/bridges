clear
set more off
capture log close
log using results/pooled_event_study.log, text replace

do create_variables  `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' 

forval r=1/12 {
	gen river_mile_`r' = river_mile*(river=="``r''")
}

xtpoisson total i.event_time river_mile_*, i(river_year) fe
test (110.event_time+120.event_time+130.event_time+140.event_time)/4==(0+70.event_time+80.event_time+90.event_time)/4
gen po_hat = .
gen se = .
foreach t in 70 80 90 100 110 120 130 140 {
	replace po_hat = _b[`t'.event_time] if event_time==`t'
	replace se = _se[`t'.event_time] if event_time==`t'
}
replace po_hat = 0 if event_time==60
replace se = 0 if event_time==60

replace event_time = event_time - offset
label var po_hat "Post office count (log)"
label var event_time "Years since bridge"

gen upper = po_hat + 1.96*se
gen lower = po_hat - 1.96*se
tw (area  upper lower event_time, base(-0.05 -0.05) sort astyle( ci plotregion)) (line po_hat event_time, sort),  scheme(s2color) legend(order(1 "95% confidence interval" 3 "Post office count (log)"))
graph save results/pooled_event_study.gph, replace


capture log close
