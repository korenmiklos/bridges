RIVERS = arkansas colorado columbia connecticut delaware hudson mississippi missouri ohio red snake tennessee
results: results/pooled.gph results/pooled_event_study.gph results/clustering.gph
count: $(foreach river,$(RIVERS),data/$(river).csv)
results/pooled.log results/pooled.gph: $(foreach river,$(RIVERS),data/$(river).csv) pooled.do create_variables.do estimate_and_plot.do
	stata-mp -b do pooled $(foreach river,$(RIVERS),$(river))
results/pooled_event_study.log results/pooled_event_study.gph: $(foreach river,$(RIVERS),data/$(river).csv) event_study.do create_variables.do
	stata-mp -b do event_study $(foreach river,$(RIVERS),$(river))
results/clustering.log results/clustering.gph: $(foreach river,$(RIVERS),data/$(river).csv) clustering.do create_variables.do
	stata-mp -b do clustering $(foreach river,$(RIVERS),$(river))
data/%.csv: ../../data/rivers/%/right_bank.geojson ../../data/rivers/%/left_bank.geojson ../../data/us-postal-history/consistent/postoffices.geojson count_left_right_post_offices.py
	python count_left_right_post_offices.py $(basename $(notdir $@)) > $@
