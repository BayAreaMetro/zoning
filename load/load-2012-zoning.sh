#This script can be used to re-generate a postgres database dump of 
#the 2012 zoning data in the source geodatabases
#it is unlikely that this would need to occur
#as long as legacy2012.dump already exists

DBUSERNAME=$1
DBPASSWORD=$2
DBHOST=$3
DBPORT=$4
DBNAME=$5

# RUN COMMENTED COMMANDS IN THE VM, OR ELSE DO THEM IN PGADMIN
# #drop if db exists
# sudo -u postgres psql legacy_2012_zoning -c "create extension postgis;"
# sudo -u postgres psql legacy_2012_zoning -c "create extension postgis_topology;"

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase1.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase2.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase3.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase4.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase5.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase6.gdb

#the layer for santa clara city in the geodatabase does not match the CityAssignments "Match field" so we replace it with a shapefile from the santa clara directory that does:
ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" /data/source_zoning_data_missing_from_GDB/SantaClara/City_Santa_Clara_GP_LU_02.shp

# sudo -u postgres legacy_2012_zoning -c 'ALTER SCHEMA public RENAME TO zoning_legacy_2012;'
# sudo -u postgres legacy_2012_zoning -c 'ALTER TABLE zoning_legacy_2012.export_output RENAME TO zoning_legacy_2012.monte_sereno;'

# sudo -u postgres legacy_2012_zoning -skipfailures -f scraps/alter_table_multiple_schema.sql

# rm legacy2012.dump

# sudo -u postgres psql -f lookup-table-merge-2012-zoning.sql
# sudo -u postgres pg_dump legacy_2012_zoning > legacy2012.dump

# sudo -u postgres psql landuse < legacy2012.dump



