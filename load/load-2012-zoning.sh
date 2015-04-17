#This script can be used to re-generate a postgres database dump of 
#the 2012 zoning data in the source geodatabases
#it is unlikely that this would need to occur
#as long as legacy2012.dump already exists

DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=25432
DBNAME=staging 

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase1.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase2.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase3.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase4.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase5.gdb

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data_source/PlannedLandUsePhase6.gdb

psql -p 25432 -h localhost -U vagrant staging -c 'ALTER SCHEMA public RENAME TO zoning_legacy_2012;'
sudo -p 25432 -h localhost -U vagrant staging -c 'ALTER TABLE zoning_legacy_2012.export_output RENAME TO zoning_legacy_2012.monte_sereno;'
sudo -p 25432 -h localhost -U vagrant staging -c 'DROP TABLE zoning_legacy_2012.pacificagp_022009;'
# sudo -u postgres plu -skipfailures -f scraps/alter_table_multiple_schema.sql
# rm legacy2012.dump

# sudo -u postgres psql -f lookup-table-merge-2012-zoning.sql
# sudo -u postgres pg_dump plu > plannedlanduse.sql
# sudo -u postgres psql landuse < legacy2012.dump



