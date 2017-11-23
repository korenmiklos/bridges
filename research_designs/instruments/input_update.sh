cp ../../data/us-postal-history/consistent/postoffices.geojson input/us-postal-history/postoffices.geojson
for river in arkansas colorado columbia connecticut delaware hudson missouri ohio red snake tennessee mississippi
do
	cp ../../data/rivers/$river/river.geojson input/rivers/$river/river_midline.geojson
	cp ../../data/rivers/$river/bridges.geojson input/rivers/$river/bridges.geojson 
done
