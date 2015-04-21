DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#CITY BOUNDARIES
ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI data_source/city10_ba.shp
#had to delete columns: sqmi, aland, awater b/c stored as numeric(17,17) 
#which was beyond capabilities of shapefile, latter 2 replaced with INT, former easy to make w/PostGIS
#old file saved here: http://landuse.s3.amazonaws.com/zoning/city10_ba_original.zip

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI data_source/county10_ca.shp

PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE SCHEMA zoning_staging"

#JURISDICTION-BASED ZONING SOURCE DATA
ls data_source/jurisdictional/*.shp | cut -d "/" -f3 | xargs -I {} ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI -nln zoning_staging.{} data_source/jurisdictional/{}

#GENERIC ZONING CODE TABLE
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/load-generic-zoning-code-table.sql

#PLU-BASED ZONING SOURCE DATA
ogr2ogr -f "PostgreSQL" PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" data_source/PLU2008_Updated.shp

#UPDATE9 PARCELS from ba8
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < data_source/ba8_parcels.sql

#UPDATE9 TABLE (joinnuma, zoning_id)
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/update9.sql
