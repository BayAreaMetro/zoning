DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#CITY BOUNDARIES
ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
../data_source/admin-boundaries/city10_ba.shp

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
../data_source/admin-boundaries/count10_ca.shp

#JURISDICTION-BASED ZONING SOURCE DATA
ls ../data_source/jurisdictional/*.shp | xargs -I {} ogr2ogr -nlt PROMOTE_TO_MULTI -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" {}

#GENERIC ZONING CODE TABLE
psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load-generic-zoning-code-table.sql

#PLU-BASED ZONING SOURCE DATA
ogr2ogr -f "PostgreSQL" PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" ../data_source/PLU2008_Updated.shp
pg_dump $(ARGS) vagrant --table=plu2008_updated > plu_bay_area_zoning.sql

#UPDATE9 PARCELS from ba8
psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < ../data_source/ba8_parcels.sql

#UPDATE9 TABLE (joinnuma, zoning_id)
psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/update9.sql
