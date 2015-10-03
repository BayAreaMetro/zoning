DROP TABLE IF EXISTS zoning.contested_parcel_in_counties_single_max;
CREATE TABLE zoning.contested_parcel_in_counties_single_max
AS 
SELECT z.geom_id, z.zoning_id, z.juris, z.zoning, z.prop, z.tablename, p.geom 
FROM
parcel p, 
zoning.counties_parcel_overlaps_maxonly z
 where (z.geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.counties_parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof=1
	)
 AND p.geom_id = z.geom_id;
 COMMENT ON TABLE zoning.contested_parcel_in_counties_single_max is 'derived from parcels/zoning overlaps for parcels intersecting counties-one max value';

DROP TABLE IF EXISTS zoning.contested_parcel_in_counties_multiple_max;
CREATE TABLE zoning.contested_parcel_in_counties_multiple_max
AS 
SELECT z.geom_id, z.zoning_id, z.juris, z.zoning, z.prop, z.tablename, p.geom 
FROM
parcel p, 
zoning.counties_parcel_overlaps_maxonly z
 where (z.geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.counties_parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	)
 AND p.geom_id = z.geom_id;
 COMMENT ON TABLE zoning.contested_parcel_in_counties_multiple_max is 'derived from parcels/zoning overlaps for parcels intersecting counties-multiple max values';

DROP INDEX IF EXISTS zoning_contested_parcel_in_counties_multiple_max;
CREATE INDEX zoning_contested_parcel_in_counties_multiple_max ON zoning.contested_parcel_in_counties_multiple_max using GIST (geom);

vacuum (analyze) zoning.contested_parcel_in_counties_multiple_max;

DROP TABLE IF EXISTS zoning.parcel_geo3;
CREATE TABLE zoning.parcel_geo3 AS
SELECT *
FROM zoning.contested_parcel_in_counties_single_max;
COMMENT ON TABLE zoning.parcel_geo1 is 'A geo-table of parcel intersection from counties';

DROP INDEX IF EXISTS zoning_parcel_geo2_gidx;
CREATE INDEX zoning_parcel_geo2_gidx ON zoning.parcel_geo2 using GIST (geom);
vacuum (analyze) zoning.parcel_geo2;

DROP TABLE IF EXISTS zoning.parcel_contested3;
CREATE TABLE zoning.parcel_contested3 AS
SELECT *
FROM parcel
WHERE geom_id NOT IN (SELECT geom_id FROM zoning.parcel);
COMMENT ON TABLE zoning.parcel_contested3 is 'A geo-table of parcels with more than 1 intersection, and not in city intersection or county intersection based on 2011 data. ';

CREATE INDEX zoning_parcel_contested_gidx ON zoning.parcel_contested2 using GIST (geom);

vacuum (analyze) zoning.parcel_contested3;
vacuum (analyze) zoning.parcel_geo3;

INSERT INTO zoning.parcel 
SELECT geom_id, zoning_id, zoning, juris, prop, tablename from 
zoning.contested_parcel_in_counties_single_max
WHERE geom_id NOT IN (SELECT geom_id from zoning.parcel);
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;

--DROP TO SAVE SPACE (TEMPORARY FOR VAGRANT VM)