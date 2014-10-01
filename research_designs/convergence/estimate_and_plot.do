areg small_share treatment*, a(river_year) cluster(river_segment)
*test (treatment70+treatment80+treatment80)/3==(treatment110+treatment120+treatment130)/3
predict small_share_hat, xb
gen se = .
forval t=70/130 {
	replace se = _se[treatment`t'] if event_time==`t'
}
*replace se = _se[_cons] if event_time==70

xi: areg change i.after*lag_deviation, a(river_year)  cluster(river_segment)

replace event_time = event_time - offset
label var small_share_hat "Share of smaller side of the river"
label var event_time "Years since bridge"

gen upper = small_share_hat + 1.96*se
gen lower = small_share_hat - 1.96*se
tw (area  upper lower event_time, sort astyle( ci plotregion)) (line small_share_hat event_time, sort),  scheme(s2color) legend(order(1 "95% confidence interval" 3 "Share of smaller side of the river"))
