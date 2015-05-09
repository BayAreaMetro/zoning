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

CREATE INDEX city_santa_clara_gidx ON zoning_staging.City_Santa_Clara_GP_LU_02 using GIST (wkb_geometry);

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
ST_INTERSECTS(z.wkb_geometry,scp.geom) AND
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
select * from GetOverlaps('zoning.parcels_with_multiple_zoning_santa_clara','zoning_staging.City_Santa_Clara_GP_LU_02','GP_DESIGNA','wkb_geometry') as codes(
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
SELECT geom_id, zoning_id from zoning.parcel_intersection_santa_clara where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count_santa_clara WHERE countof=1);

INSERT INTO zoning.parcel 
SELECT pz.geom_id, c.zoning_id 
from zoning.parcel_overlaps_maxonly_santa_clara pz,
zoning.codes_dictionary c
WHERE 
c.name=pz.zoning_string;



EOF




