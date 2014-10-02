RIVERS = arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi
.PHONY: regression iv.log
iv.log: segments
	stata-mp -b do iv
	touch $@
segments: $(foreach river,$(RIVERS),output/$(river).csv) 
output/%.csv: ../../data/rivers/%/river.geojson input/%/river_poly.geojson input/%/predicted_crossing_points.geojson instruments_by_segment.py project_geojson.py
	python instruments_by_segment.py $(notdir $(basename $@)) > $@
