# if using the postgres/postgis development vm, https://github.com/buckleytom/pg-app-dev-vm, 
# the user will need to create a file called ~/.pgpass with the following line:
# localhost:25432:vagrant:vagrant:vagrant
#need to add
# parcels_zoning_santa_clara.sql
# parcels_fairfield.sql: 

#the following are just stubs and won't work right now

get = perl s3-curl/s3curl.pl --id=company -- http://landuse.s3.amazonaws.com/zoning/
ARGS = 

parcel_zoning.csv: bay_area_zoning.sql \
	data_source/parcels_spandex.sql \
	plu_bay_area_zoning.sql \
	update9_parcels.sql \
	data_source/ba8_parcels.sql
	psql $(ARGS) vagrant process/update9places.sql
	psql $(ARGS) vagrant process/parcel_zoning_intersection.sql

	psql $(ARGS) vagrant -f process/merge_jurisdiction_zoning.sql

#########################
####LOAD IN POSTGRES#####
#########################

bay_area_zoning.sql: data_source/PlannedLandUsePhase1.gdb \
	data_source/zoning_codes_base2012.csv \
	data_source/match_fields_tables_zoning_2012_source.csv
	bash load/load-2012-zoning.sh
	psql -p 5432 -h localhost -U vagrant vagrant -f load/load-generic-zoning-code-table.sql

update9_parcels.sql: data_source/Parcels2010_Update9.sql data_source/ba8_parcels.sql
	psql $(ARGS) vagrant < data_source/ba8_parcels.sql

data_source/Parcels2010_Update9.sql: data_source/Parcels2010_Update9.csv
	psql $(ARGS) vagrant -f load/update9.sql
	pg_dump $(ARGS) vagrant --table=Parcels2010_Update9 > data_source/Parcels2010_Update9.sql

data_source/PLU2008_Updated.shp

##############
###PREPARE####
##############

data_source/jurisdictional/AlamedaCountyGP2006db.shp: data_source/PlannedLandUsePhase1.gdb
	load/jurisdiction_shapefile_directory.sh

data_source/PlannedLandUsePhase1.gdb: data_source/PlannedLandUse1Through6.gdb.zip
	unzip -d data_source/ data_source/PlannedLandUse1Through6.gdb.zip

data_source/county10_ba.shp: data_source/county10_ba.zip
	unzip -d data_source/ data_source/county10_ba.zip
	touch data_source/county10_ba.shp

data_source/city10_ba.shp: data_source/city10_ba.zip
	unzip -d data_source/ data_source/city10_ba.zip
	touch data_source/city10_ba.shp

##############
###DOWNLOAD###
##############

#where plu refers to the old "planned land use"/comprehensive plan project
data_source/ba8_parcels.sql: 
	$(get)ba8parcels.sql \
	-o data_source/ba8_parcels.sql

data_source/city10_ba.zip:
	$(get)city10_ba.zip \
	-o data_source/city10_ba.zip

data_source/county10_ba.zip:
	$(get)county10_ba.zip \
	-o data_source/county10_ba.zip

data_source/match_fields_tables_zoning_2012_source.csv:
	$(get)match_fields_tables_zoning_2012_source.csv \
	-o data_source/match_fields_tables_zoning_2012_source.csv

data_source/parcels_spandex.sql:
	$(get)parcels_spandex.sql \
	-o data_source/parcels_spandex.sql

data_source/Parcels2010_Update9.csv:
	$(get)Parcels2010_Update9.csv \
	-o data_source/Parcels2010_Update9.csv	

data_source/PlannedLandUse1Through6.gdb.zip:
	$(get)PlannedLandUse1Through6.gdb.zip \
	-o data_source/PlannedLandUse1Through6.gdb.zip

data_source/PLU2008_Updated.shp: data_source/PLU2008_Updated.zip
	unzip -d data_source/ data_source/PLU2008_Updated
	touch data_source/PLU2008_Updated.shp 

data_source/PLU2008_Updated.zip:
	$(get)PLU2008_Updated.zip \
	-o data_source/PLU2008_Updated.zip

data_source/zoning_codes_base2012.csv:
	$(get)zoning_codes_base2012.csv \
	-o data_source/zoning_codes_base2012.csv

s3curl/s3curl.pl: s3curl.zip
	unzip s3-curl.zip

s3curl.zip:
	curl -o s3-curl.zip http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip

clean: clean_db clean_shapefiles

clean_db:
	sudo bash load/clean_db.sh

clean_shapefiles:
	rm -rf data_source/jurisdictional
