CREATE INDEX parcel_idx ON parcels USING GIST (geom);

CREATE INDEX zoning_lookup_idx ON zoning.lookup_new_valid USING GIST (the_geom);

CREATE TABLE zoning.parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning.lookup_2012_valid as z, parcel p
			WHERE ST_Intersects(z.geom, p.geom)
			GROUP BY geom_id;

--Need to run non-intersection query, the following returns 0 rows
DROP TABLE IF EXISTS zoning.parcels_with_no_zoning;
CREATE TABLE zoning.parcels_with_no_zoning AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=0);


DROP TABLE zoning.parcels_with_multiple_zoning;
CREATE TABLE zoning.parcels_with_multiple_zoning AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof>1);
--Query returned successfully: 517549 rows affected, 13805 ms execution time.

DROP TABLE IF EXISTS zoning.parcels_with_one_zone;
CREATE TABLE zoning.parcels_with_one_zone AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);
--Query returned successfully: 1303120 rows affected, 22743 ms execution time.

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

ALTER TABLE zoning.parcels_with_one_zone
    RENAME id TO p_id;

ALTER TABLE zoning.regional
    RENAME id TO z_id;    

CREATE TABLE zoning.parcel AS
select p.geom_id, z.id, 100 as prop
from zoning.parcels_with_one_zone p,
zoning.regional z
WHERE ST_Intersects(z.the_geom, p.geom);
