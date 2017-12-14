local resolution 1
local proximity 1000

tempfile bridges rivers postoffices
save `bridges', replace emptyok
save `rivers', replace emptyok
save `postoffices', replace emptyok

* historical crossing points at following rivermiles
local x_connecticut 68 86 144 197
local x_hudson 42 67 93 154 220
local x_delaware 128 139 146
local x_tennessee 190 369 400
local x_ohio 897 810 626 586 494
* from 1800 map
local x_mississippi 64 313 533 658 881 923 
local x_missouri 130 353 600 770 1020 1179 1354 1575 2095 2260
local x_arkansas 112 312 364 757
* from 1800 map
local x_colorado 917 941 
local x_columbia 277 690
local x_red 129 373
local x_snake 1 120 263 590 648 681 749 782 


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

	* distance to nearest historical crossing
	local crossings : word count `x_`river''
	forval i=1/`crossings' {
		local crossing : word `i' of `x_`river''
		gen distance_`i' = abs(river_mile-`crossing')
	}
	capture egen closest_crossing = rmin(distance_*)
	capture drop distance_*

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
