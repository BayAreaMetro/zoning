DBUSERNAME=$1
DBPASSWORD=$2
DBHOST=$3
DBPORT=$4
DBNAME=$5

# RUN THESE COMMENTED COMMANDS IN THE VM, OR ELSE DO THEM IN PGADMIN
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

# sudo -u postgres legacy_2012_zoning -c 'ALTER SCHEMA public RENAME TO zoning_legacy_2012;'
# sudo -u postgres legacy_2012_zoning -c 'ALTER TABLE zoning_legacy_2012.export_output RENAME TO zoning_legacy_2012.monte_sereno;'

# sudo -u postgres legacy_2012_zoning -skipfailures -f scraps/alter_table_multiple_schema.sql

# rm legacy2012.dump
# sudo -u postgres pg_dump legacy_2012_zoning > legacy2012.dump
# sudo -u postgres psql landuse < legacy2012.dump

