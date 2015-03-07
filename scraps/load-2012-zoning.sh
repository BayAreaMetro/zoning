DBUSERNAME=$1
DBPASSWORD=$2
DBHOST=$3
DBPORT=$4
DBNAME=$5

#drop if db exists
sudo -u postgres dropdb $DBNAME
sudo -u postgres createdb $DBNAME

# BECAUSE THE ANACONDA INSTALL OF OGR2OGR SEEMS TO NOT SUPPORT POSTGRES, DO THIS OUTSIDE VM
# ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase1.gdb

# /usr/bin/ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase2.gdb

# /usr/bin/ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase3.gdb

# /usr/bin/ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase4.gdb

# /usr/bin/ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase5.gdb

# /usr/bin/ogr2ogr -skipfailures -f "PostgreSQL" \
# PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
# /zoning_data/PlannedLandUsePhase6.gdb

sudo -u postgres $DBNAME -f 'CREATE SCHEMA zoning_legacy_2012;'
sudo -u postgres $DBNAME -c 'ALTER TABLE zoning_legacy_2012.export_output RENAME TO zoning_legacy_2012.monte_sereno;'

sudo -u postgres $DBNAME -skipfailures -f scraps/alter_table_multiple_schema.sql

sudo -u postgres pg_dump $DBNAME > $DBNAME.dump
sudo -u postgres psql landuse < $DBNAME.dump

