clear
tempfile zip
local placefile zcta_cbsa_rel_10.txt
*local placefile zcta_place_rel_10.txt
local placename cbsa
*local placename place

insheet using ../../data/population/zipcode/Zipcode-ZCTA-Population-Density-And-Area-Unsorted.csv
gen egy = 1
ren land area
ren density density
ren zipzcta zcta5
save `zip'

insheet using ../../data/population/zipcode/`placefile', clear comma names
* only keep zip codes that do not overlap across MSAs
keep if zpoppct>90
* only keep metro areas
keep if memi==1

merge 1:1 zcta5 using `zip',
expand 2, generate(duplicate)

replace `placename' = 99999 if duplicate

sort `placename' density

foreach X in area population {
	by `placename': gen sum_`X' = sum(`X')
	egen total_`X' = max(sum_`X'), by(`placename')
	replace sum_`X' = sum_`X'/total_`X'
	label var sum_`X' "Cumulative share of `X'"
}
egen half_of_people = min(cond(sum_population>=0.5,sum_area,.)), by(`placename')
replace half_of_people = 100-100*half_of_people

egen placetag = tag(`placename')
su half_of_people if placetag, d
*table `placename', c(mean half_of_people)

gen log_density = log(density)
anova log_density `placename' 

tw (line sum_population sum_area if cbsa==35620, sort) (line sum_population sum_area if cbsa==99999, sort), legend(order(1 "NYC" 2 "All ZIP codes")) 
graph export ../../text/exhibits/zipcode-lorenz.pdf, replace
