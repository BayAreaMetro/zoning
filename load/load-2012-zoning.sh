#This script can be used to re-generate a postgres database dump of 
#the 2012 zoning data in the source geodatabases
#it is unlikely that this would need to occur
#as long as legacy2012.dump already exists

# DBUSERNAME=$DBUSERNAME
# DBPASSWORD=$DBPASSWORD
# DBHOST=$DBHOST
# DBPORT=$DBPORT
# DBNAME=plu 

#might need to:
sudo -u postgres createuser -s vagrant
#ALTER USER username CREATEDB

createdb -U vagrant plu 

# RUN COMMENTED COMMANDS IN THE VM, OR ELSE DO THEM IN PGADMIN
# #drop if db exists
psql plu -c "create extension postgis;"
psql plu -c "create extension postgis_topology;"

ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase1.gdb

# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# data/PlannedLandUsePhase2.gdb

# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# data/PlannedLandUsePhase3.gdb

# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# data/PlannedLandUsePhase4.gdb

# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# data/PlannedLandUsePhase5.gdb

# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# data/PlannedLandUsePhase6.gdb

# sudo -u postgres plu -c 'ALTER SCHEMA public RENAME TO zoning_legacy_2012;'
# sudo -u postgres plu -c 'ALTER TABLE zoning_legacy_2012.export_output RENAME TO zoning_legacy_2012.monte_sereno;'
# sudo -u postgres plu -skipfailures -f scraps/alter_table_multiple_schema.sql
# rm legacy2012.dump

# sudo -u postgres psql -f lookup-table-merge-2012-zoning.sql
# sudo -u postgres pg_dump plu > plannedlanduse.sql
# sudo -u postgres psql landuse < legacy2012.dump



