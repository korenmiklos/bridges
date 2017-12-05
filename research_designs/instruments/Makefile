RIVERS = arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi
iv.log: segments
	stata-mp -b do iv
segments: $(foreach river,$(RIVERS),output/$(river).csv) $(foreach river,$(RIVERS),input/rivers/$(river)/bridges.csv) $(foreach river,$(RIVERS),temp/post_offices/$(river).csv) 
	touch $@
input/%/bridges.csv: input/%/bridges.geojson geojson2csv.py
	python2.7 geojson2csv.py < $< > $@
output/%.csv: input/rivers/%/river_midline.geojson input/rivers/%/river_poly.geojson width_by_mile.py project_geojson.py
	python2.7 width_by_mile.py $(notdir $(basename $@)) > $@
temp/post_offices/%.csv: input/rivers/%/river_midline.geojson input/rivers/%/river_poly.geojson input/us-postal-history/postoffices.geojson post_offices_by_mile.py project_geojson.py
	python2.7 post_offices_by_mile.py $(notdir $(basename $@)) > $@
