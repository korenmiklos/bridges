local RIVERS arkansas colorado columbia connecticut delaware hudson  missouri ohio red snake tennessee mississippi

tempfile rivers
clear
save `rivers', replace emptyok

foreach river in `RIVERS' {
	insheet using data/`river'.csv, clear
	gen str river = "`river'"
	append using `rivers'
	save `rivers', replace
}

egen river_number = group(river)
su river_number
local N = r(max)

forval n=1/`N' {
	gen river_mile_`n' = river_mile*(river_number==`n')
}

gen segment = int(river_mile*1.6/30)
egen cluster = group(river segment)

reg bridges river_mile_* water_covered_area, cluster(cluster)
