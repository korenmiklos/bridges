clear
set more off
capture log close
log using results/pooled.log, text replace

do create_variables  `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' 
do estimate_and_plot
graph save results/pooled.gph, replace


capture log close
