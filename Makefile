# data_source/zoning_codes_dictionary.sql: /zoning_data/zoning_codes_dictionary.csv
# 	psql -f load/load-generic-zoning-table.sql

# data_source/plannedlanduse.sql: data_source/PlannedLandUsePhase1.gdb
# 	bash load/load-2012-zoning.sh

#the following are just stubs and won't work right now
parcel_zoning.csv: bay_area_zoning.sql \
	zoning_santa_clara.sql \
	parcels_spandex.sql \
	plu_bay_area_zoning.sql \
	parcels_zoning_update9.sql \
	parcels_zoning_fairfield.sql \
	parcels_ba8.sql
	psql -f process/update9places.sql
	psql -f process/parcel_zoning_intersection.sql

bay_area_zoning.sql: jurisdiction_zoning.sql
	psql -f process/merge_jurisdiction_zoning.sql

#where plu refers to the old "planned land use"/comprehensive plan project
plu_bay_area_zoning.sql: plu_counties_zoning.sql
	psql -f process/merge_plu_counties_zoning.sql

jurisdiction_zoning.sql:
	perl s3-curl/s3curl.pl --id=company 
	-- http://landuse.s3.amazonaws.com/zoning/jurisdiction_zoning.sql \
	-o data_source/jurisdiction_zoning.sql

parcels_spandex.sql:
	perl s3-curl/s3curl.pl --id=company 
	-- http://landuse.s3.amazonaws.com/zoning/parcels_spandex.sql \
	-o data_source/parcels_spandex.sql

update9_parcels.sql: data_source/Parcels2010_Update9.csv
	psql -f load/update9.sql

parcels_ba8.sql: 
	perl s3-curl/s3curl.pl --id=company 
	-- http://landuse.s3.amazonaws.com/zoning/parcels_ba8.sql \
	-o data_source/parcels_ba8.sql

#need to add:
# zoning_santa_clara.sql: 

# parcels_fairfield.sql: 

# since FileGDB requires gdal 1.11 and ubuntu trusty gdal is 1.10,
# just loading these from sql dumps for now.
# can fix this when GDAL 1.11/2.0 gets released
#
# data_source/PlannedLandUsePhase1.gdb: data_source/PlannedLandUse1Through6.gdb.zip
# 	unzip -d data_source/ data_source/PlannedLandUse1Through6.gdb.zip

# data_source/PlannedLandUse1Through6.gdb.zip: s3-curl/s3curl.pl
# 	perl s3-curl/s3curl.pl --id=company 
# 	-- http://landuse.s3.amazonaws.com/zoning/PlannedLandUse1Through6.gdb.zip \
# 	-o data_source/PlannedLandUse1Through6.gdb.zip

data_source/zoning_data/zoning_codes_dictionary.csv: s3-curl/s3curl.pl
	perl s3-curl/s3curl.pl --id=company \
	-- http://landuse.s3.amazonaws.com/zoning/zoning_data/zoning_codes_dictionary.csv -o data_source/zoning_codes_dictionary.csv 

s3curl/s3curl.pl: s3curl.zip
	unzip s3-curl.zip

s3curl.zip:
	curl -o s3-curl.zip http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
