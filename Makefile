get = perl s3-curl/s3curl.pl --id=company -- http://landuse.s3.amazonaws.com/zoning/
DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#########################
##Join Parcels/Zoning####
#########################

parcel_zoning.csv: zoningdb.sql
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/merge_jurisdiction_zoning.sql
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/parcel_zoning_intersection.sql
#########################
####LOAD IN POSTGRES#####
#########################

zoningdb.sql: \
	data_source/ba8parcels.sql \
	data_source/city10_ba.shp \
	data_source/county10_ca.shp \
	data_source/match_fields_tables_zoning_2012_source.csv \
	data_source/parcels_spandex.sql \
	data_source/Parcels2010_Update9.csv \
	data_source/jurisdictional/AlamedaCountyGP2006db.shp \
	data_source/zoning_codes_base2012.csv \
	data_source/PLU2008_Updated.shp
	bash load/all-in-postgres.sh

##############
###PREPARE####
##############

data_source/jurisdictional/AlamedaCountyGP2006db.shp: data_source/PlannedLandUsePhase1.gdb
	bash load/jurisdiction_shapefile_directory.sh

data_source/PlannedLandUsePhase1.gdb: data_archive/PlannedLandUse1Through6.gdb.zip
	unzip -o -d data_source/ data_archive/PlannedLandUse1Through6.gdb.zip
	touch data_source/PlannedLandUsePhase1.gdb

data_source/county10_ca.shp: data_archive/county10_ca.zip
	unzip -o -d data_source/ data_archive/county10_ca.zip
	touch data_source/county10_ca.shp

data_source/city10_ba.shp: data_archive/city10_ba.zip
	unzip -o -d data_source/ data_archive/city10_ba.zip
	touch data_source/city10_ba.shp

data_source/PLU2008_Updated.shp: data_archive/PLU2008_Updated.zip
	unzip -o -d data_source/ data_archive/PLU2008_Updated.zip
	touch data_source/PLU2008_Updated.shp 

##############
###DOWNLOAD###
##############

#where plu refers to the old "planned land use"/comprehensive plan project
data_source/ba8parcels.sql: s3-curl/s3curl.pl
	$(get)ba8parcels.sql \
	-o data_source/ba8parcels.sql

data_source/parcels_spandex.sql: s3-curl/s3curl.pl
	$(get)parcels_spandex.sql \
	-o data_source/parcels_spandex.sql

data_source/Parcels2010_Update9.csv: s3-curl/s3curl.pl
	$(get)Parcels2010_Update9.csv \
	-o data_source/Parcels2010_Update9.csv	

data_source/zoning_codes_base2012.csv: s3-curl/s3curl.pl
	$(get)zoning_codes_base2012.csv \
	-o data_source/zoning_codes_base2012.csv

data_archive/city10_ba.zip: s3-curl/s3curl.pl
	$(get)city10_ba.zip \
	-o data_archive/city10_ba.zip

data_archive/county10_ca.zip: s3-curl/s3curl.pl
	$(get)county10_ca.zip \
	-o data_archive/county10_ca.zip

data_source/match_fields_tables_zoning_2012_source.csv: s3-curl/s3curl.pl
	$(get)match_fields_tables_zoning_2012_source.csv \
	-o data_source/match_fields_tables_zoning_2012_source.csv

data_archive/PlannedLandUse1Through6.gdb.zip: s3-curl/s3curl.pl
	$(get)PlannedLandUse1Through6.gdb.zip \
	-o data_archive/PlannedLandUse1Through6.gdb.zip

data_archive/PLU2008_Updated.zip: s3-curl/s3curl.pl
	$(get)PLU2008_Updated.zip \
	-o data_archive/PLU2008_Updated.zip

s3-curl/s3curl.pl: s3-curl.zip
	unzip -o s3-curl.zip
	touch s3-curl/s3curl.pl
	mkdir -p data_archive
	mkdir -p data_source

s3-curl.zip:
	curl -o s3-curl.zip http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip

clean: clean_db clean_shapefiles

clean_db:
	sudo bash load/clean_db.sh

clean_shapefiles:
	rm -rf data_source/jurisdictional
