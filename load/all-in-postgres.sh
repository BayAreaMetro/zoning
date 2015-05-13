DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#CITY BOUNDARIES
ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI city10_ba.shp
#had to delete columns: sqmi, aland, awater b/c stored as numeric(17,17) 
#which was beyond capabilities of shapefile, latter 2 replaced with INT, former easy to make w/PostGIS
#old file saved here: http://landuse.s3.amazonaws.com/zoning/city10_ba_original.zip

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI county10_ca.shp

PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE SCHEMA zoning_staging"

#JURISDICTION-BASED ZONING SOURCE DATA
ls jurisdictional/*.shp | cut -d "/" -f2 | xargs -I {} ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI -lco SCHEMA=zoning_staging jurisdictional/{} > source_zoning_import_errors.log 2>&1

#FIX for Napa
ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" -select zoning \
-nlt PROMOTE_TO_MULTI -lco SCHEMA=zoning_staging -lco OVERWRITE=YES jurisdictional/NapaCoZoning.shp

#FIX for Solano
ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" -select full_name \
-nlt PROMOTE_TO_MULTI -lco SCHEMA=zoning_staging -lco OVERWRITE=YES jurisdictional/SolCoGeneral_plan_unincorporated.shp

#GENERIC ZONING CODE TABLE
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/load-generic-zoning-code-table.sql

#PLU-BASED ZONING SOURCE DATA
ogr2ogr -f "PostgreSQL" PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" PLU2008_Updated.shp

#UPDATE9 PARCELS from ba8
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < ba8parcels.sql

#SPANDEX PARCELS
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < parcels_spandex.sql

#UPDATE9 TABLE (joinnuma, zoning_id)
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/update9.sql

#PLU-2006 Zoning Data 
ogr2ogr -f "PostgreSQL" PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" plu06_may2015estimate.shp
