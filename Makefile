#$@ is the file name of the target of the rule. 
get = perl s3curl.pl --id=company -- http://landuse.s3.amazonaws.com/zoning/
DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#########################
##Join Parcels/Zoning####
#########################

parcel_zoning.csv:
	mkdir -p data_out
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/merge_jurisdiction_zoning.sql
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f process/parcel_zoning_intersection.sql
#########################
####LOAD IN POSTGRES#####
#########################

load_data: ba8parcels.sql \
	city10_ba.shp \
	county10_ca.shp \
	match_fields_tables_zoning_2012_source.csv \
	parcels_spandex.sql \
	Parcels2010_Update9.csv \
	jurisdictional/AlamedaCountyGP2006db.shp \
	zoning_codes_base2012.csv \
	PLU2008_Updated.shp
	bash load/all-in-postgres.sh

##############
###PREPARE####
##############

jurisdictional/AlamedaCountyGP2006db.shp: PlannedLandUsePhase1.gdb
	bash load/jurisdiction_shapefile_directory.sh
	touch jurisdictional/*

PlannedLandUsePhase1.gdb: PlannedLandUse1Through6.gdb.zip
	unzip -o -d  $@
	touch $@

county10_ca.shp: county10_ca.zip
	unzip -o -d  $@
	touch $@

city10_ba.shp: city10_ba.zip
	unzip -o -d  $@
	touch $@

PLU2008_Updated.shp: PLU2008_Updated.zip
	unzip -o -d  $@
	touch $@

##############
###DOWNLOAD###
##############

#where plu refers to the old "planned land use"/comprehensive plan project
ba8parcels.sql: s3curl.pl
	$(get)ba8parcels.sql \
	-o $@.download
	mv $@.download $@

parcels_spandex.sql: s3curl.pl
	$(get)parcels_spandex.sql \
	-o $@.download
	mv $@.download $@

Parcels2010_Update9.csv: s3curl.pl
	$(get)Parcels2010_Update9.csv \
	-o $@.download
	mv $@.download $@

zoning_codes_base2012.csv: s3curl.pl
	$(get)zoning_codes_base2012.csv \
	-o $@.download
	mv $@.download $@

city10_ba.zip: s3curl.pl
	$(get)city10_ba.zip \
	-o $@.download
	mv $@.download $@

zoning_codes_base2008.csv: s3curl.pl
	$(get)zoning_codes_base2008.csv \
	-o zoning_codes_base2008.csv

county10_ca.zip: s3curl.pl
	$(get)county10_ca.zip \
	-o $@.download
	mv $@.download $@

match_fields_tables_zoning_2012_source.csv: s3curl.pl
	$(get)match_fields_tables_zoning_2012_source.csv \
	-o $@.download
	mv $@.download $@

PlannedLandUse1Through6.gdb.zip: s3curl.pl
	$(get)PlannedLandUse1Through6.gdb.zip \
	-o $@.download
	mv $@.download $@

PLU2008_Updated.zip: s3curl.pl
	$(get)PLU2008_Updated.zip \
	-o $@.download
	mv $@.download $@

s3curl.pl: s3-curl.zip
	unzip -o \s3-curl.zip
	touch s3curl.pl

s3-curl.zip:
	curl -o $@ http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
	mv $@.download $@

clean: clean_db clean_shapefiles

clean_db:
	sudo bash load/clean_db.sh
	
clean_intersection_tables:
	PGPASSWORD=vagrant psql \
	-p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME) \
	-f load/drop_intersection_tables.sql

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
	rm -rf jurisdictional

sql_dump:
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel_withdetails.sql \
	vagrant
	
remove_source_data:
	rm ba8parcels.* 
	rm city10_ba.* 
	rm county10_ca.* 
	rm match_fields_tables_zoning_2012_source.* 
	rm parcels_spandex.* 
	rm Parcels2010_Update9.* 
	rm jurisdictional/*.* 
	rm zoning_codes_base2012.* 
	rm PLU2008_Updated.*
	rm PlannedLandUsePhase*
