DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=mtc 

PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE SCHEMA admin"

#BOUNDARIES
shp2pgsql city10_ba.shp admin.city10_ba | PGPASSWORD=vagrant \
psql --host=${DBHOST} --port=${DBPORT} --dbname=${DBNAME} --user=${DBUSERNAME}
#had to delete columns: sqmi, aland, awater b/c stored as numeric(17,17) 
#which was beyond capabilities of shapefile, latter 2 replaced with INT, former easy to make w/PostGIS
#old file saved here: http://landuse.s3.amazonaws.com/zoning/city10_ba_original.zip

shp2pgsql county10_ca.shp admin.county10_ca | PGPASSWORD=vagrant \
psql --host=${DBHOST} --port=${DBPORT} --dbname=${DBNAME} --user=${DBUSERNAME}

PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE SCHEMA zoning_staging"

#JURISDICTION-BASED ZONING SOURCE DATA
ls jurisdictional/*.shp | cut -d "/" -f2 | sed 's/.shp//' | \
xargs -I {} shp2pgsql jurisdictional/{} zoning_staging.{} | PGPASSWORD=vagrant \
psql --host=${DBHOST} --port=${DBPORT} --dbname=${DBNAME} --user=${DBUSERNAME}

#FIX for Napa
#Can't SELECT with shp2pgsql--trying this:
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE TABLE zoning_staging.napacozoning_temp AS SELECT zoning from napacozoning;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "DROP TABLE zoning_staging.napacozoning;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE TABLE napacozoning AS SELECT * from zoning_staging.napacozoning_temp;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "DROP TABLE zoning_staging.napacozoning_temp;"

#FIX for Solano
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE TABLE zoning_staging.SolCoGeneral_plan_unincorporated_temp AS SELECT zoning from zoning_staging.SolCoGeneral_plan_unincorporated;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "DROP TABLE zoning_staging.SolCoGeneral_plan_unincorporated;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "CREATE TABLE zoning_staging.SolCoGeneral_plan_unincorporated AS SELECT * from zoning_staging.SolCoGeneral_plan_unincorporated_temp;"
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -c "DROP TABLE zoning_staging.SolCoGeneral_plan_unincorporated_temp;"

#GENERIC ZONING CODE TABLE
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/load-generic-zoning-code-table.sql

#PLU-BASED ZONING SOURCE DATA
#USING 2006, so 2008 NOT NECESSARY ANYMORE
#ogr2ogr -f "PostgreSQL" PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" PLU2008_Updated.shp

#UPDATE9 PARCELS from ba8
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < ba8parcels.sql

#SPANDEX PARCELS
#THIS TABLE SHOULD ALREADY EXIST IN THE DB
#PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME < parcels_spandex.sql

#UPDATE9 TABLE (joinnuma, zoning_id)
PGPASSWORD=vagrant psql -p $DBPORT -h $DBHOST -U $DBUSERNAME $DBNAME -f load/update9.sql

#PLU-2006 Zoning Data 
shp2pgsql  plu06_may2015estimate.shp zoning.plu06_may2015estimate | PGPASSWORD=vagrant \
psql --host=${DBHOST} --port=${DBPORT} --dbname=${DBNAME} --user=${DBUSERNAME}
