RIVERS = arkansas colorado columbia connecticut delaware hudson mississippi missouri ohio red snake tennessee
segments: $(foreach river,$(RIVERS),data/$(river).csv) 
data/%.csv: ../../data/rivers/%/river.geojson ../../data/rivers/%/river_poly.geojson instruments_by_segment.py project_geojson.py
	python instruments_by_segment.py $(notdir $(basename $@)) > $@
