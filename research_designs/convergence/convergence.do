clear
set more off
capture log close
log using results/`1'.log, text replace

do create_variables `1'

xtreg left i.event_time i.year, i(river_bridge) fe
xtreg right i.event_time i.year, i(river_bridge) fe

xtreg small_share after i.year, i(river_bridge) fe
areg small_share i.event_time, a(year) cluster(river_segment)
test (110.event_time+120.event_time+130.event_time+140.event_time)/4==(0+70.event_time+80.event_time+90.event_time)/4
predict small_share_hat, xb
gen se = .
foreach t in 70 80 90 100 110 120 130 140 {
	replace se = _se[`t'.event_time] if event_time==`t'
}
replace se = _se[_cons] if event_time==60

xi: areg change i.after*lag_deviation, a(river_year)  cluster(river_segment)

replace event_time = event_time - offset
label var small_share_hat "Share of smaller side of the river"
label var event_time "Years since bridge"

gen upper = small_share_hat + 1.96*se
gen lower = small_share_hat - 1.96*se
tw (area  upper lower event_time, sort astyle( ci plotregion)) (line small_share_hat event_time, sort),  scheme(s2color) legend(order(1 "95% confidence interval" 3 "Share of smaller side of the river"))
graph save results/`1'.gph, replace

capture log close
