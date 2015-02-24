DBUSERNAME=$1
DBPASSWORD=$2
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=DBUSERNAME dbname=lgcy_znng_2012 password=DBPASSWORD port=5432" /d/legacy/zoning/zoning_2012.gdb -a_srs EPSG:26910