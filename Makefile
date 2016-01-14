#$@ is the file name of the target of the rule. 
#example get from s3:aws s3 cp s3://landuse/zoning/match_fields_tables_zoning_2012_source.csv match_fields_tables_zoning_2012_source.csv
get = aws s3 cp s3://landuse/zoning/
get_zoning = aws s3 cp s3://zoning-sf-bay-area/
DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=mtc 
psql = PGPASSWORD=vagrant psql -p $(DBPORT) -h $(DBHOST) -U $(DBUSERNAME) $(DBNAME)
shp2pgsql = shp2pgsql -t 2D -s 26910 -I

#########################
##Join Parcels/Zoning####
#########################

zoning_parcels.csv: \
	load_administrative_tables \
	load_zoning_data \
	prepare \
	intersect \
	assign \
	plu06 \
	load_no_dev \
	apply_no_dev \
	backup_db \
	$(psql) mtc -f process/output_maps_and_tables.sql \
	python output/fix_zoning_missing_id.py

output_csv:
	$(psql) -c "\COPY zoning.parcel to 'zoning_parcels.csv' DELIMITER ',' CSV HEADER;"
	$(psql) -c "\COPY zoning.parcel to 'zoning_parcels_no_dev_as_zero.csv' DELIMITER ',' CSV HEADER;"

update_after_change_in_zoning_ids: \
	intersect \
	assign \
	backup_db

prepare: merge_2012_zoning \
	clean_geoms \
	assign_admin 

clean_geoms: \
	$(psql) -f process/clean_parcel_geoms.sql
	$(psql) -f process/clean_2012_zoning_geoms.sql
	$(psql) -f process/clean_plu06_geoms.sql

merge_2012_zoning:
	$(psql) -f functions/merge_schema.sql
	$(psql) -f process/merge_2012_zoning.sql

assign_admin:
	$(psql) -f process/assign_admin_to_parcels.sql

intersect: create_intersection_table \
	get_stats_on_intersection 

create_intersection_table:
	$(psql) -c "SET enable_seqscan TO off;"
	$(psql) -f functions/get_zoning_id.sql
	$(psql) -f process/create_intersection_table.sql #22m in 100GB VM

get_stats_on_intersection:
	$(psql) -f process/get_stats_on_intersection.sql

assign: assign_simple

assign_simple:
	assign_zoning_to_parcels_with_one_zone

assign_zoning_to_parcels_with_one_zone:
	$(psql) -f process/assign_zoning_to_parcels_with_one_zone.sql

###########
###plu06###
###########

plu06: \
	create_intersection_table_plu06 \
	overlaps_plu06 \
	assign_plu06

create_intersection_table_plu06:
	$(psql) -f process/create_intersection_table_plu06.sql

overlaps_plu06:
	$(psql) -f process/overlaps_plu06_missing_parcels.sql

assign_plu06:
	$(psql) -f process/assign_plu06_to_parcels.sql		

check_output:
	$(psql) -f process/check_zoning_parcel_table.sql
	$(psql) -f process/output_maps_and_tables.sql

#########################
####LOAD IN POSTGRES#####
#########################

load_pda: pda.shp
	$(shp2pgsql) pda.shp admin.pda | $(psql)

load_administrative_tables: \
	load_admin_boundaries \
	create_jurisdiction_table \

load_zoning_data: \
	load_zoning_shapefiles \
	load_zoning_shapefile_metadata \
	load_plu06 \
	fix_errors_in_source_zoning

load_admin_boundaries: city10_ba.shp county10_ca.shp load_census_county_boundaries
	$(psql) -c "DROP SCHEMA if exists admin_staging CASCADE"
	$(psql) -c "CREATE SCHEMA admin_staging"
	$(shp2pgsql) city10_ba.shp admin_staging.city10_ba | $(psql)
	#for city10_ba had to delete columns: sqmi, aland, awater b/c stored as numeric(17,17) 
	#which was beyond capabilities of shapefile, latter 2 replaced with INT, former easy to make w/PostGIS
	#old file saved here: http://landuse.s3.amazonaws.com/zoning/city10_ba_original.zip
	$(shp2pgsql) county10_ca.shp admin_staging.county10_ca | $(psql)

create_jurisdiction_table:
	$(psql) -f process/create_jurisdictional_table.sql



legacy_tablenames := $(shell cat zoning_source_metadata.csv | cut -d ',' -f2 | tr '\n' ' ')
zip_targets = $(addprefix jurisdictional/, $(addsuffix .shp.zip, $(legacy_tablenames)))
shp_targets = $(addprefix jurisdictional/, $(addsuffix .shp, $(legacy_tablenames)))

testme:
	echo $(legacy_tablenames)

zoning_files: $(shp_targets)

$(shp_targets): $(zip_targets)
	unzip -d jurisdictional -o $@.zip
	touch $@

$(zip_targets):
	$(get_zoning)$(@F) \
	$@.download
	mv $@.download $@

load_zoning_shapefiles: zoning_files
	$(psql) -c "DROP SCHEMA IF EXISTS zoning_staging CASCADE"
	$(psql) -c "CREATE SCHEMA zoning_staging"
	#    $(foreach jurisdiction, $(legacy_tablenames), $(shp2pgsql) $(jurisdiction) zoning_staging.$(jurisdiction) | $(psql);)
	ls jurisdictional/*.shp | cut -d "/" -f2 | sed 's/.shp//' | \
	xargs -I {} $(shp2pgsql) jurisdictional/{} zoning_staging.{} | \
	$(psql)

load_zoning_data_by_city: cities_towns/AlamedaGeneralPlan.shp
	cd cities_towns; rm SonomaCountyGeneralPlan.* \
			   SolCoGeneral_plan_unincorporated.* \
			   SanMateoCountyZoning.* \
			   SantaClaraCountyGenPlan.* \
			   NapaCoZoning.* \
			   MarinCountyGenPlan.* \
			   CCCountyGPLandUse.* \
			   AlamedaCountyGP2006db.*
	$(psql) -c "DROP SCHEMA IF EXISTS zoning_cities_towns CASCADE"
	$(psql) -c "CREATE SCHEMA zoning_cities_towns"
	ls cities_towns/*.shp | cut -d "/" -f2 | sed 's/.shp//' | \
	xargs -I {} $(shp2pgsql) cities_towns/{} zoning_cities_towns.{} | \
	$(psql)

load_zoning_data_by_county: unincorporated_counties/SonomaCountyGeneralPlan.shp
	$(psql) -c "DROP SCHEMA IF EXISTS zoning_unincorporated_counties CASCADE"
	$(psql) -c "CREATE SCHEMA zoning_unincorporated_counties"
	ls unincorporated_counties/*.shp | cut -d "/" -f2 | sed 's/.shp//' | \
	xargs -I {} $(shp2pgsql) unincorporated_counties/{} zoning_unincorporated_counties.{} | \
	$(psql)

load_zoning_codes: zoning_lookup.csv
	$(psql) -f load/load-generic-zoning-code-table.sql

load_zoning_shapefile_metadata:
	$(psql) -f load/load-zoning-shapefile-metadata.sql

load_zoning_code_additions:
	$(psql) -f load/add_missing_codes.sql

fix_string_matching_in_zoning_table: match_fields_tables_zoning_2012_source.csv
	$(psql) -f load/zoning_codes_fix_string_matching.sql

fix_errors_in_source_zoning:
	#FIX for Napa
	#Can't SELECT with shp2pgsql--trying this:
	$(psql) -c "CREATE TABLE zoning_staging.napacozoning_temp AS SELECT zoning, geom from zoning_staging.napacozoning;"
	$(psql) -c "DROP TABLE zoning_staging.napacozoning;"
	$(psql) -c "CREATE TABLE zoning_staging.napacozoning AS SELECT * from zoning_staging.napacozoning_temp;"
	$(psql) -c "DROP TABLE zoning_staging.napacozoning_temp;"

	#FIX for Solano
	$(psql) -c "CREATE TABLE zoning_staging.solcogeneral_plan_unincorporated_temp AS SELECT full_name, geom from zoning_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "DROP TABLE zoning_staging.solcogeneral_plan_unincorporated;"
	$(psql) -c "CREATE TABLE zoning_staging.solcogeneral_plan_unincorporated AS SELECT * from zoning_staging.solcogeneral_plan_unincorporated_temp;"
	$(psql) -c "DROP TABLE zoning_staging.solcogeneral_plan_unincorporated_temp;"

load_plu06: jurisdictional/plu06_may2015estimate.shp
	$(psql) -c "DROP TABLE IF EXISTS zoning.plu06_may2015estimate;"
	$(shp2pgsql) plu06_may2015estimate.shp zoning_staging.plu06_may2015estimate | $(psql)
	$(psql) -f load/add-plu-2006.sql

load_no_dev: no_dev1_geo_only.csv
	$(psql) -f load/no_dev.sql

apply_no_dev:
	$(psql) -f process/apply_no_dev.sql

##############
###PREPARE####
##############

pda.shp: pda.shp.zip
	unzip -o $<
	touch $@

City_Santa_Clara_GP_LU_02.shp: City_Santa_Clara_GP_LU_02.zip
	unzip -o $<
	touch $@

cities_towns/AlamedaGeneralPlan.shp: jurisdictional/AlamedaGeneralPlan.shp
	mkdir -p cities_towns
	cp jurisdictional/* cities_towns/
	touch cities_towns/*

unincorporated_counties/SonomaCountyGeneralPlan.shp: jurisdictional/SonomaCountyGeneralPlan.shp
	mkdir -p unincorporated_counties
	cd jurisdictional; mv -t ../unincorporated_counties SonomaCountyGeneralPlan.* \
				   SolCoGeneral_plan_unincorporated.* \
				   SanMateoCountyZoning.* \
				   SantaClaraCountyGenPlan.* \
				   NapaCoZoning.* \
				   MarinCountyGenPlan.* \
				   CCCountyGPLandUse.* \
				   AlamedaCountyGP2006db.*
	cd ..
	touch unincorporated_counties/*

jurisdictional/SonomaCountyGeneralPlan.shp: PlannedLandUsePhase1.gdb/a00000001.freelist
	mkdir -p jurisdictional
	bash load/jurisdiction_shapefile_directory.sh
	touch jurisdictional/*

PlannedLandUsePhase1.gdb/a00000001.freelist: PlannedLandUse1Through6.gdb.zip
	unzip -o $<
	touch $@

census_county.shp: gz_2010_us_050_00_5m.zip


county10_ca.shp: county10_ca.zip
	unzip -o $<
	touch $@

city10_ba.shp: city10_ba.zip
	unzip -o $<

jurisdictional/plu06_may2015estimate.shp: jurisdictional/plu06_may2015estimate.zip
	unzip -o $<
	touch $@	

##############
###DOWNLOAD###
##############

no_dev1_geo_only.csv:
	$(get)$@ \
	$@.download
	mv $@.download $@

pda.shp.zip: 
	$(get)$@ \
	$@.download
	mv $@.download $@

City_Santa_Clara_GP_LU_02.zip: 
	$(get)$@ \
	$@.download
	mv $@.download $@

#where plu refers to the old "planned land use"/comprehensive plan project
ba8parcels.sql:
	$(get)ba8parcels.sql \
	$@.download
	mv $@.download $@

parcels_spandex.sql:
	$(get)parcels_spandex.sql \
	$@.download
	mv $@.download $@

zoning_lookup.csv:
	curl -k -o $@.download https://raw.githubusercontent.com/MetropolitanTransportationCommission/bayarea_urbansim/master/data/zoning_lookup.csv?token=AAGCjC_Z9YDWbVUtwzTkKBHJgYdXwJqtks5WDHVUwA%3D%3D 
	mv $@.download $@

city10_ba.zip:
	$(get)city10_ba.zip \
	$@.download
	mv $@.download $@

county10_ca.zip:
	$(get)county10_ca.zip \
	$@.download
	mv $@.download $@

match_fields_tables_zoning_2012_source.csv:
	$(get)match_fields_tables_zoning_2012_source.csv \
	$@.download
	mv $@.download $@

PlannedLandUse1Through6.gdb.zip:
	$(get)PlannedLandUse1Through6.gdb.zip \
	$@.download
	mv $@.download $@

jurisdictional/plu06_may2015estimate.zip:
	$(get)plu06_may2015estimate.zip \
	$@.download
	mv $@.download $@

no_dev1.txt:
	$(get)$@ \
	$@.download
	mv $@.download $@
	touch $@

###################
##General Targets##
###################

zoning_parcel_intersection:
	$(psql) \
	-f process/parcel_zoning_intersection.sql

sql_dump:
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel_withdetails.sql \
	vagrant
	pg_dump --table zoning.parcel_withdetails \
	-f /mnt/bootstrap/zoning/data_out/zoning_parcel.sql \
	vagrant

backup_db:
	bash output/backup_db.sh 
	bash output/write_db_to_s3.sh

write_db_to_s3:
	bash output/write_db_to_s3.sh

##################################
##extras##########################
##################################
##everything down here is not#####
##part of the main target creation
##################################

clean_zoning_data:
	$(psql) -c "DROP SCHEMA zoning CASCADE;"
	$(psql) -c "DROP SCHEMA zoning_staging CASCADE;"

clean_db:
	sudo bash load/clean_db.sh

clean_intersection_tables:
	$(psql)	-f load/drop_intersection_tables.sql

clean_parcel_generation:
	$(psql)	-f load/drop_parcel_generation_tables.sql

clean_shapefiles:
	rm -rf jurisdictional

remove_source_data:
	rm ba8parcels.* 
	rm city10_ba.* 
	rm county10_ca.* 
	rm match_fields_tables_zoning_2012_source.* 
	rm parcels_spandex.* 
	rm Parcels2010_Update9.* 
	rm jurisdictional/*.* 
	rm PLU2008_Updated.*
	rm PlannedLandUsePhase*

reload_plu06: load_plu06 clean_plu06_geoms plu_06



#########################
###Join Parcels/PDAs#####
#########################
parcels_pdas.csv:
	load_pda \
	$(psql) -f process/get_pda_for_parcels.sql


##################################################
###following may be useful later, not used now####
####for loading/checks against census source #####
##################################################

load_census_city_boundaries: gz_2010_06_160_00_500k.shp
        shp2pgsql -W "LATIN1" -t 2D -s 26910 -I gz_2010_06_160_00_500k.shp admin_staging.gz_2010_06_160_00_500k | $(psql)

gz_2010_06_160_00_500k.shp: gz_2010_06_160_00_500k.zip
        unzip -o gz_2010_06_160_00_500k.zip

gz_2010_06_160_00_500k.zip:
        curl -k -o $@.download http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_06_160_00_500k.zip
        mv $@.download $@

load_census_county_boundaries: gz_2010_us_050_00_5m.shp
        shp2pgsql -W "LATIN1" -t 2D -s 26910 -I gz_2010_us_050_00_5m.shp admin_staging.gz_2010_us_050_00_5m | $(psql)

gz_2010_us_050_00_5m.shp: gz_2010_us_050_00_5m.zip
        unzip -o $<

gz_2010_us_050_00_5m.zip:
        curl -k -o $@.download http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_us_050_00_5m.zip
        mv $@.download $@

##################################################
##################END CENSUS IMPORT###############
####for loading/checks against census source #####
##################################################


gdb_table_list:
	ls jurisdictional/*.shp | cut -d "/" -f2 | \
	sed 's/.shp//' | tr '[A-Z]' '[a-z]'| sort > gdb_table_list

zip_up_shapefiles:
	ls *.shp | sed 's/.shp//' | \
	xargs -I {} zip -r {}.zip . -i {}.shp.*
