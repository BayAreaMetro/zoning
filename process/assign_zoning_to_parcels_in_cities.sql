DROP TABLE IF EXISTS zoning.contested_parcel_in_cities_single_max;
CREATE TABLE zoning.contested_parcel_in_cities_single_max
AS 
SELECT z.geom_id, z.zoning_id, z.prop, z.tablename, p.geom 
FROM
parcel p, 
zoning.cities_parcel_overlaps_maxonly z
 where (z.geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.cities_parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof=1
	)
 AND p.geom_id = z.geom_id;
 COMMENT ON TABLE zoning.contested_parcel_in_cities_multiple_max is 'derived from parcels/zoning overlaps for parcels intersecting cities-one max value';

DROP TABLE IF EXISTS zoning.contested_parcel_in_cities_multiple_max;
CREATE TABLE zoning.contested_parcel_in_cities_multiple_max
AS 
SELECT z.geom_id, z.zoning_id, z.prop, z.tablename, p.geom 
FROM
parcel p, 
zoning.cities_parcel_overlaps_maxonly z
 where (z.geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.cities_parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	)
 AND p.geom_id = z.geom_id;
 COMMENT ON TABLE zoning.contested_parcel_in_cities_multiple_max is 'derived from parcels/zoning overlaps for parcels intersecting cities-multiple max values';

DROP INDEX zoning_contested_parcel_in_cities_multiple_max;
CREATE INDEX zoning_contested_parcel_in_cities_multiple_max ON zoning.contested_parcel_in_cities_multiple_max using GIST (geom);

vacuum (analyze) zoning.contested_parcel_in_cities_multiple_max;

DROP TABLE IF EXISTS zoning.parcel_geo2;
CREATE TABLE zoning.parcel_geo2 AS
SELECT *
FROM zoning.contested_parcel_in_cities_single_max;
COMMENT ON TABLE zoning.parcel_geo1 is 'A geo-table of parcel intersection from cities'

CREATE INDEX zoning_parcel_geo2_gidx ON zoning.parcel_geo2 using GIST (geom);
vacuum (analyze) zoning.parcel_geo2;

DROP TABLE IF EXISTS zoning.parcel_contested2;
CREATE TABLE zoning.parcel_contested2 AS
SELECT *
FROM parcel
WHERE geom_id NOT IN (SELECT geom_id FROM zoning.parcel);
COMMENT ON TABLE zoning.parcel_contested2 is 'A geo-table of parcels with more than 1 intersection not in city intersection';

CREATE INDEX zoning_parcel_contested_gidx ON zoning.parcel_contested2 using GIST (geom);

vacuum (analyze) zoning.parcel_contested;
vacuum (analyze) zoning.parcel_geo1;

INSERT INTO zoning.parcel 
SELECT geom_id, zoning_id, prop, tablename from 
zoning.contested_parcel_in_cities_single_max;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;