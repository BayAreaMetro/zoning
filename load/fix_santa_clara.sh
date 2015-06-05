DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#FIX for Santa Clara
ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI -lco SCHEMA=zoning_staging -lco OVERWRITE=YES City_Santa_Clara_GP_LU_02.shp

psql <<EOF
update zoning.source_field_name 
set tablename='City_Santa_Clara_GP_LU_02' 
where juris=27;

update zoning.source_field_name 
set matchfield='GP_DESIGNA' 
where juris=27;

CREATE INDEX city_santa_clara_gidx ON zoning_staging.City_Santa_Clara_GP_LU_02 using GIST (geom);

VACUUM (ANALYZE) zoning_staging.City_Santa_Clara_GP_LU_02;

CREATE TABLE zoning.parcel_intersection_santa_clara AS
SELECT c.id as zoning_id, scp.geom_id
FROM
(select geom_id, geom from 
parcel where
geom_id in 
(select geom_id from
zoning.parcel_cities_counties
where cityname1 = 'Santa Clara') ) scp,
zoning_staging.City_Santa_Clara_GP_LU_02 z,
zoning.codes_dictionary c
WHERE 
ST_INTERSECTS(z.geom,scp.geom) AND
c.name=z.GP_DESIGNA;

DROP TABLE IF EXISTS zoning.parcel_intersection_count_santa_clara;
CREATE TABLE zoning.parcel_intersection_count_santa_clara AS
SELECT geom_id, count(*) as countof FROM
			zoning.parcel_intersection_santa_clara
			GROUP BY geom_id;

CREATE INDEX zoning_parcel_intersection_count_santa_clara ON zoning.parcel_intersection_count_santa_clara (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count_santa_clara;

DROP VIEW IF EXISTS zoning.parcels_with_multiple_zoning_santa_clara;
CREATE VIEW zoning.parcels_with_multiple_zoning_santa_clara AS
SELECT geom_id, geom from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count_santa_clara WHERE countof>1);

--read in overlaps function
\i process/get_overlaps_function.sql

DROP TABLE IF EXISTS zoning.parcel_overlaps_santa_clara;
CREATE TABLE zoning.parcel_overlaps_santa_clara AS
select * from GetOverlaps('zoning.parcels_with_multiple_zoning_santa_clara','zoning_staging.City_Santa_Clara_GP_LU_02','GP_DESIGNA','geom') as codes(
		geom_id bigint, 
  		zoning_string varchar(42),
		area double precision,
		prop double precision,
		geom geometry);

DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly_santa_clara;
CREATE TABLE zoning.parcel_overlaps_maxonly_santa_clara AS
SELECT geom_id, zoning_string, prop 
FROM zoning.parcel_overlaps_santa_clara WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps_santa_clara
  GROUP BY geom_id
);


INSERT INTO zoning.parcel 
SELECT count(*) 
from zoning.parcel_overlaps_maxonly_santa_clara pz,
zoning.codes_dictionary c
WHERE 
c.name=pz.zoning_string AND
c.juris=27;

--the above doesn't work because the string matching doesn't work. here are the strings in santa clara source:

# -------------------------------
#  MODERATE DENSITY RESIDENTIAL
#  EDUCATION
#  OFFICE/RESEARCH & DEVELOPMENT
#  TRANSIT-ORIENTED MIXED USE
#  INSTITUTIONAL
#  OPEN SPACE
#  SINGLE FAMILY DETACHED
#  THOROUGHFARE
#  SINGLE FAMILY ATTACHED
#  PARKS & RECREATION
#  MEDIUM DENSITY RESIDENTIAL
#  GATEWAY THOROUGHFARE
#  MIXED USE


# here are the strings for santa clara in the codes_base2012.csv spreadsheet

# Very Low Density Residential
# Low Density Residential
# Medium Density Residential
# High Density Residential
# Neighborhood Commercial
# Community Commercial
# Regional Commercial
# Neighborhood Mixed Use
# Community Mixed Use
# Regional Mixed Use
# High Intensity Office/R&D
# Low Intensity Office/R&D
# Light Industrial
# Heavy Industrial
# Public/Quasi Public
# Parks/Open Space
# Downtown Core




EOF




