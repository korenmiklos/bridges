local resolution 1
local proximity 1000

tempfile bridges rivers postoffices
save `bridges', replace emptyok
save `rivers', replace emptyok
save `postoffices', replace emptyok

foreach river in arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi {
	di "`river'"
	insheet using input/rivers/`river'/bridges.csv, clear
	gen bridge = _n
	gen str river = "`river'"
	
	capture drop duplicates
	collapse (min) start, by(river river_mile)

	ren start first_bridge

	append using `bridges'
	save `bridges', replace

	insheet using temp/post_offices/`river'.csv, clear
	replace river_mile = int(river_mile)
	gen str river = "`river'"

	keep if distance_to_river<`proximity'
	
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
