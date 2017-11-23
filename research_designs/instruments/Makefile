RIVERS = arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi
iv.log: segments
	stata-mp -b do iv
segments: $(foreach river,$(RIVERS),output/$(river).csv) 
	touch $@
output/%.csv: input/rivers/%/river_midline.geojson input/rivers/%/river_poly.geojson input/rivers/%/predicted_crossing_points.geojson instruments_by_segment.py project_geojson.py
	python2.7 instruments_by_segment.py $(notdir $(basename $@)) > $@
