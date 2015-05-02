#$@ is the file name of the target of the rule. 
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
	touch data_source/jurisdictional/*

data_source/PlannedLandUsePhase1.gdb: data_archive/PlannedLandUse1Through6.gdb.zip
	unzip -o -d data_source/ $@
	touch $@

data_source/county10_ca.shp: data_archive/county10_ca.zip
	unzip -o -d data_source/ $@
	touch $@

data_source/city10_ba.shp: data_archive/city10_ba.zip
	unzip -o -d data_source/ $@
	touch $@

data_source/PLU2008_Updated.shp: data_archive/PLU2008_Updated.zip
	unzip -o -d data_source/ $@
	touch $@

##############
###DOWNLOAD###
##############

#where plu refers to the old "planned land use"/comprehensive plan project
data_source/ba8parcels.sql: s3-curl/s3curl.pl
	$(get)ba8parcels.sql \
	-o $@.download
	mv $@.download $@

data_source/parcels_spandex.sql: s3-curl/s3curl.pl
	$(get)parcels_spandex.sql \
	-o $@.download
	mv $@.download $@

data_source/Parcels2010_Update9.csv: s3-curl/s3curl.pl
	$(get)Parcels2010_Update9.csv \
	-o $@.download
	mv $@.download $@

data_source/zoning_codes_base2012.csv: s3-curl/s3curl.pl
	$(get)zoning_codes_base2012.csv \
	-o $@.download
	mv $@.download $@

data_archive/city10_ba.zip: s3-curl/s3curl.pl
	$(get)city10_ba.zip \
	-o $@.download
	mv $@.download $@

data_archive/county10_ca.zip: s3-curl/s3curl.pl
	$(get)county10_ca.zip \
	-o $@.download
	mv $@.download $@

data_source/match_fields_tables_zoning_2012_source.csv: s3-curl/s3curl.pl
	$(get)match_fields_tables_zoning_2012_source.csv \
	-o $@.download
	mv $@.download $@

data_archive/PlannedLandUse1Through6.gdb.zip: s3-curl/s3curl.pl
	$(get)PlannedLandUse1Through6.gdb.zip \
	-o $@.download
	mv $@.download $@

data_archive/PLU2008_Updated.zip: s3-curl/s3curl.pl
	$(get)PLU2008_Updated.zip \
	-o $@.download
	mv $@.download $@

s3-curl/s3curl.pl: s3-curl.zip
	unzip -o s3-curl.zip
	touch s3-curl/s3curl.pl
	mkdir -p data_archive
	mkdir -p data_source

s3-curl.zip:
	curl -o $@ http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
	mv $@.download $@

clean: clean_db clean_shapefiles

clean_db:
	sudo bash load/clean_db.sh

create_db:
	sudo bash load/clean_db.sh

clean_zoning_intersection:
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f load/drop_intersection_tables.sql

merge_source_zoning:
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/merge_jurisdiction_zoning.sql

zoning_parcel_intersection:
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/parcel_zoning_intersection.sql

clean_shapefiles:
	rm -rf data_source/jurisdictional
