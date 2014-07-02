clear
set more off
capture log close
log using results/pooled.log, text replace

do create_variables  `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' 

areg small_share i.event_time , a(river_year) cluster(river_segment)
test (110.event_time+120.event_time+130.event_time+140.event_time)/4==(0+70.event_time+80.event_time+90.event_time)/4
predict small_share_hat, xb
gen se = .
foreach t in 70 80 90 100 110 120 130 140 {
	replace se = _se[`t'.event_time] if event_time==`t'
}
replace se = _se[_cons] if event_time==60

xi: areg change i.after*lag_deviation, a(river_year)  cluster(river_segment)
tempvar hat

gen fitted=.
forval t=-4/4 {
	di in ye "`t'0"
	areg small L10.large L10.small if event_time==`t'*10+offset, a(river_year) cluster(river_segment)
	predict `hat', xb
	replace fitted=`hat' if event_time==`t'*10+offset
	drop `hat'
}
BRK

replace event_time = event_time - offset
label var small_share_hat "Share of smaller side of the river"
label var event_time "Years since bridge"

gen upper = small_share_hat + 1.96*se
gen lower = small_share_hat - 1.96*se
tw (area  upper lower event_time, sort astyle( ci plotregion)) (line small_share_hat event_time, sort),  scheme(s2color) legend(order(1 "95% confidence interval" 3 "Share of smaller side of the river"))
graph save results/pooled.gph, replace


capture log close
