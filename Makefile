#$@ is the file name of the target of the rule. 
#example get from s3:aws s3 cp s3://landuse/zoning/match_fields_tables_zoning_2012_source.csv match_fields_tables_zoning_2012_source.csv
get = aws s3 cp s3://landuse/zoning/
DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=mtc 
psql = PGPASSWORD=vagrant psql -p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME)

#########################
##Join Parcels/Zoning####
#########################

parcel_zoning.csv:
	mkdir -p data_out
	$(psql) -f process/merge_jurisdiction_zoning.sql
	$(psql) -f process/parcel_zoning_intersection.sql

add_plu06:
	$(psql) \
	-f load/add-plu-2006.sql

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
	PLU2008_Updated.shp \
	plu06_may2015estimate.shp \
	load_zoning_by_jursidiction
	fix_errors_in_source_zoning
	load_admin_boundaries
	add_update9
	add_plu06

load_admin_boundaries:
	$(psql) -c "CREATE SCHEMA admin"
	shp2pgsql city10_ba.shp admin.city10_ba | $(psql)
	#for city10_ba had to delete columns: sqmi, aland, awater b/c stored as numeric(17,17) 
	#which was beyond capabilities of shapefile, latter 2 replaced with INT, former easy to make w/PostGIS
	#old file saved here: http://landuse.s3.amazonaws.com/zoning/city10_ba_original.zip
	shp2pgsql county10_ca.shp admin.county10_ca | $(psql)

load_zoning_by_jursidiction:
	$(psql) -c "CREATE SCHEMA zoning_staging"
	#JURISDICTION-BASED ZONING SOURCE DATA
	ls jurisdictional/*.shp | cut -d "/" -f2 | sed 's/.shp//' | \
	xargs -I {} shp2pgsql jurisdictional/{}.shp zoning_staging.{} | \
	$(psql)

load_zoning_codes:
	$(psql) -f load/load-generic-zoning-code-table.sql

fix_errors_in_source_zoning:
	#FIX for Napa
	#Can't SELECT with shp2pgsql--trying this:
	$(psql) -c "CREATE TABLE zoning_staging.napacozoning_temp AS SELECT zoning from zoning_staging.napacozoning;"
	$(psql) -c "DROP TABLE zoning_staging.napacozoning;"
	$(psql) -c "CREATE TABLE zoning_staging.napacozoning AS SELECT * from zoning_staging.napacozoning_temp;"
	$(psql) -c "DROP TABLE zoning_staging.napacozoning_temp;"

	#FIX for Solano
	$(psql) -c "CREATE TABLE zoning_staging.solcogeneral_plan_unincorporated_temp AS SELECT full_name from zoning_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "DROP TABLE zoning_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "CREATE TABLE zoning_staging.solcogeneral_plan_unincorporated AS SELECT * from zoning_staging.solcogeneral_plan_unincorporated_temp;"
	$(psql) -c "DROP TABLE zoning_staging.solcogeneral_plan_unincorporated_temp;"

load_plu06:
	shp2pgsql plu06_may2015estimate.shp zoning.plu06_may2015estimate | $(psql)

##############
###PREPARE####
##############

City_Santa_Clara_GP_LU_02.shp: City_Santa_Clara_GP_LU_02.zip
	unzip -o $<
	touch $@

jurisdictional/AlamedaCountyGP2006db.shp: PlannedLandUsePhase1.gdb
	bash load/jurisdiction_shapefile_directory.sh
	touch jurisdictional/*

PlannedLandUsePhase1.gdb: PlannedLandUse1Through6.gdb.zip
	unzip -o $<
	touch $@

county10_ca.shp: county10_ca.zip
	unzip -o $<
	touch $@

city10_ba.shp: city10_ba.zip
	unzip -o $<
	touch $@

PLU2008_Updated.shp: PLU2008_Updated.zip
	unzip -o $<
	touch $@

no_dev_array.csv: no_dev1.txt
	cp no_dev1.txt no_dev1.csv
	ogr2ogr -f csv -overwrite -select GEOM_ID no_dev_array.csv no_dev1.csv


##############
###DOWNLOAD###
##############

City_Santa_Clara_GP_LU_02.zip: 
	$(get)$@ \
	$@.download
	mv $@.download $@

#where plu refers to the old "planned land use"/comprehensive plan project
ba8parcels.sql: s3curl.pl
	$(get)ba8parcels.sql \
	$@.download
	mv $@.download $@

parcels_spandex.sql: s3curl.pl
	$(get)parcels_spandex.sql \
	$@.download
	mv $@.download $@

Parcels2010_Update9.csv: s3curl.pl
	$(get)Parcels2010_Update9.csv \
	$@.download
	mv $@.download $@

zoning_codes_base2012.csv: s3curl.pl
	$(get)zoning_codes_base2012.csv \
	$@.download
	mv $@.download $@

city10_ba.zip: s3curl.pl
	$(get)city10_ba.zip \
	$@.download
	mv $@.download $@

zoning_codes_base2008.csv: s3curl.pl
	$(get)zoning_codes_base2008.csv \
	-o zoning_codes_base2008.csv

county10_ca.zip: s3curl.pl
	$(get)county10_ca.zip \
	$@.download
	mv $@.download $@

match_fields_tables_zoning_2012_source.csv: s3curl.pl
	$(get)match_fields_tables_zoning_2012_source.csv \
	$@.download
	mv $@.download $@

PlannedLandUse1Through6.gdb.zip: s3curl.pl
	$(get)PlannedLandUse1Through6.gdb.zip \
	$@.download
	mv $@.download $@

PLU2008_Updated.zip: s3curl.pl
	$(get)PLU2008_Updated.zip \
	$@.download
	mv $@.download $@

plu06_may2015estimate.zip: s3curl.pl
	$(get)plu06_may2015estimate.zip \
	$@.download
	mv $@.download $@

no_dev1.txt: s3curl.pl
	$(get)$@ \
	$@.download
	mv $@.download $@
	touch $@

s3curl.pl: s3-curl.zip
	unzip -o \s3-curl.zip
	touch s3curl.pl

s3-curl.zip:
	curl -o $@ http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
	mv $@.download $@

###################
##General Targets##
###################

clean: clean_db clean_shapefiles

clean_db:
	sudo bash load/clean_db.sh
	
clean_intersection_tables:
	PGPASSWORD=vagrant $(psql) \
	-f load/drop_intersection_tables.sql

merge_source_zoning:
	PGPASSWORD=vagrant $(psql) \
	-f process/merge_jurisdiction_zoning.sql

zoning_parcel_intersection:
	PGPASSWORD=vagrant $(psql) \
	-f process/parcel_zoning_intersection.sql

clean_shapefiles:
	rm -rf jurisdictional

sql_dump:
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel_withdetails.sql \
	vagrant
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel.sql \
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
