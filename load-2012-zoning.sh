DBUSERNAME=$1
DBPASSWORD=$2
DBHOST=$3
DBNAME=$4

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase1.gdb

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase2.gdb

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase3.gdb

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase4.gdb

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase5.gdb

ogr2ogr -f "PostgreSQL" \
PG:"host=${DBHOST} port=5432 dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
data/PlannedLandUsePhase6.gdb
