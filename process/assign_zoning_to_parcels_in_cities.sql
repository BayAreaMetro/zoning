DROP TABLE IF EXISTS zoning.contested_parcel_in_cities_single_max CASCADE;
CREATE TABLE zoning.contested_parcel_in_cities_single_max
AS 
SELECT z.geom_id, z.zoning_id, z.juris, z.zoning, z.prop, z.tablename, p.geom 
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
 COMMENT ON TABLE zoning.contested_parcel_in_cities_single_max is 'derived from parcels/zoning overlaps for parcels intersecting cities-one max value';

DROP TABLE IF EXISTS zoning.contested_parcel_in_cities_multiple_max CASCADE;
CREATE TABLE zoning.contested_parcel_in_cities_multiple_max
AS 
SELECT z.geom_id, z.zoning_id, z.juris, z.zoning,  z.prop, z.tablename, p.geom 
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

DROP INDEX IF EXISTS zoning_contested_parcel_in_cities_multiple_max;
CREATE INDEX zoning_contested_parcel_in_cities_multiple_max ON zoning.contested_parcel_in_cities_multiple_max using GIST (geom);

vacuum (analyze) zoning.contested_parcel_in_cities_multiple_max;

DROP TABLE IF EXISTS zoning.parcel_geo2 CASCADE;
CREATE TABLE zoning.parcel_geo2 AS
SELECT *
FROM zoning.contested_parcel_in_cities_single_max;
COMMENT ON TABLE zoning.parcel_geo2 is 'A geo-table of parcel intersection from cities'

DROP INDEX IF EXISTS zoning_parcel_geo2_gidx;
CREATE INDEX zoning_parcel_geo2_gidx ON zoning.parcel_geo2 using GIST (geom);
vacuum (analyze) zoning.parcel_geo2;

DROP INDEX IF EXISTS zoning_parcel_contested2_gidx;
CREATE INDEX zoning_parcel_contested2_gidx ON zoning.parcel_contested2 using GIST (geom);

INSERT INTO zoning.parcel 
SELECT geom_id, zoning_id, zoning, juris, prop, tablename from 
zoning.contested_parcel_in_cities_single_max;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;

INSERT INTO zoning.parcel 
SELECT geom_id, zoning_id, zoning, juris, prop, tablename 
from zoning.contested_parcel_in_cities_multiple_max where tablename='newarkgp2006db';
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;

create index on zoning.parcel using hash (geom_id);
vacuum (analyze) zoning.parcel;

DROP TABLE IF EXISTS zoning.parcel_contested2 CASCADE;
CREATE TABLE zoning.parcel_contested2 AS
SELECT *
FROM parcel
WHERE geom_id NOT IN (SELECT geom_id FROM zoning.parcel);
COMMENT ON TABLE zoning.parcel_contested2 is 'A geo-table of parcels with more than 1 intersection not in city intersection';
\echo 'there are this many parcels not in the zoning.parcel table:'
select count(*) from zoning.parcel_contested2;

vacuum (analyze) zoning.parcel_contested2;
vacuum (analyze) zoning.parcel_geo1;
vacuum (analyze) zoning.parcel_geo2;

--DROP TO SAVE SPACE (TEMPORARY FOR VAGRANT VM)