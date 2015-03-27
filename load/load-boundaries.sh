DBUSERNAME=$1
DBPASSWORD=$2
DBHOST=$3
DBPORT=$4
DBNAME=mtc

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/admin-boundaries/city10_ba.shp

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/admin-boundaries/count10_ca.shp