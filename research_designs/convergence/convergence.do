clear
set more off
capture log close
log using results/`1'.log, text replace

do create_variables `1'
do estimate_and_plot
graph save results/`1'.gph, replace

capture log close
