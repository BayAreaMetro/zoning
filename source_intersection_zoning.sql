CREATE INDEX parcel_idx ON parcel USING GIST (geom);

CREATE INDEX zoning_lookup_idx ON zoning.lookup_new_valid USING GIST (the_geom);

CREATE TABLE zoning.parcel_intersection_count_new AS
SELECT geom_id, count(*) as countof FROM
			zoning.regional as z, parcel p
			WHERE ST_Intersects(z.geom, p.geom)
			GROUP BY geom_id;

DROP TABLE IF EXISTS zoning.parcels_with_multiple_zoning;
CREATE TABLE zoning.parcels_with_multiple_zoning AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count_new WHERE countof>1);
--Query returned successfully: 462655 rows affected, 6854 ms execution time.

DROP TABLE IF EXISTS zoning.parcels_with_one_zone;
CREATE TABLE zoning.parcels_with_one_zone AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count_new WHERE countof=1);
--Query returned successfully: 1311776 rows affected, 16436 ms execution time.

CREATE INDEX z_parcels_with_multiple_zoning_gidx ON zoning.parcels_with_multiple_zoning USING GIST (geom);

CREATE INDEX z_parcels_with_one_zone_gidx ON zoning.parcels_with_one_zone USING GIST (geom);

VACUUM (ANALYZE) zoning.parcels_with_multiple_zoning;
VACUUM (ANALYZE) zoning.parcels_with_one_zone;

CREATE INDEX z_regional_gidx ON zoning.regional USING GIST (the_geom);
VACUUM (ANALYZE) zoning.regional;

DROP TABLE IF EXISTS zoning.parcel_overlaps;
CREATE TABLE zoning.parcel_overlaps AS
SELECT 
	geom_id,
	id,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.geom_id, 
	z.*,
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.the_geom) geom
FROM zoning.parcels_with_multiple_zoning p,
zoning.regional as z
WHERE ST_Intersects(z.the_geom, p.geom)
) f
GROUP BY 
	geom_id,
	id;
--Query returned successfully: 872362 rows affected, 4129986 ms execution time.


CREATE TABLE zoning.parcel AS
select p.geom_id, z.id, 100 as prop
from zoning.parcels_with_one_zone p,
zoning.regional z
WHERE ST_Intersects(z.the_geom, p.geom);
--Query returned successfully: 1263160 rows affected, 1140264 ms execution time.

--make a copy of it:
CREATE TABLE zoning.parcel_copy AS
select * from zoning.parcel;

--select only those pairs of geom_id, zoning_id in which prop is max
DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly;
CREATE TABLE zoning.parcel_overlaps_maxonly AS
SELECT geom_id, id, prop 
FROM zoning.parcel_overlaps WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps
  GROUP BY geom_id
);
--Query returned successfully: 535672 rows affected, 2268 ms execution time.

--create table of parcels with >1 max values
DROP TABLE IF EXISTS zoning.parcel_two_max;
CREATE TABLE zoning.parcel_two_max AS
SELECT geom_id, id, prop FROM 
zoning.parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);
--Query returned successfully: 145309 rows affected, 817 ms execution time.

--same for 1 max, except insert into parcel table
INSERT INTO zoning.parcel
SELECT geom_id, id, prop FROM 
zoning.parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof=1
	)
--Query returned successfully: 390363 rows affected, 1634 ms execution time.

--backup db
--pg_dump zoning > zoning_db.sql

--create geographic table of double max parcels for visual inspection
CREATE TABLE zoning.parcel_two_max_geo AS
SELECT zr.*,p.geom,p.geom_id,two.prop FROM 
zoning.parcel_two_max two,
parcel p,
zoning.regional zr
WHERE two.geom_id = p.geom_id
AND zr.id = two.id

CREATE INDEX zoning_parcel_overlaps_geom_idx ON zoning.parcel_overlaps USING hash (geom_id);
CREATE INDEX zoning_parcel_two_max_geom_idx ON zoning.parcel_two_max USING hash (geom_id);
CREATE INDEX zoning_parcel_overlaps_idx ON zoning.parcel_overlaps USING hash (id);
CREATE INDEX zoning_parcel_two_max_idx ON zoning.parcel_two_max USING hash (id);

--create same from overlaps union table
CREATE TABLE zoning.parcel_two_max_geo_overlaps AS
SELECT pzo.*
FROM 
zoning.parcel_two_max two,
zoning.parcel_overlaps pzo
WHERE two.geom_id = pzo.geom_id
AND two.id = pzo.id

--output a table with geographic information and generic code info for review
CREATE TABLE zoning.parcel_withdetails AS
SELECT p.geom, z.*
FROM zoning.parcel pz,
zoning.codes_base2012 z,
parcel p
WHERE pz.id = z.id AND p.geom_id = pz.geom_id