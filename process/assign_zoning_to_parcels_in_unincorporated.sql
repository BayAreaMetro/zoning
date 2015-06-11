DROP TABLE IF EXISTS zoning.contested_parcel_in_counties_single_max;
CREATE TABLE zoning.contested_parcel_in_counties_single_max
AS 
SELECT z.geom_id, z.zoning_id, z.prop, z.tablename, p.geom 
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
 COMMENT ON TABLE zoning.contested_parcel_in_counties_multiple_max is 'derived from parcels/zoning overlaps for parcels intersecting counties-one max value';

DROP TABLE IF EXISTS zoning.contested_parcel_in_counties_multiple_max;
CREATE TABLE zoning.contested_parcel_in_counties_multiple_max
AS 
SELECT z.geom_id, z.zoning_id, z.prop, z.tablename, p.geom 
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

DROP INDEX zoning_contested_parcel_in_counties_multiple_max;
CREATE INDEX zoning_contested_parcel_in_counties_multiple_max ON zoning.contested_parcel_in_counties_multiple_max using GIST (geom);

vacuum (analyze) zoning.contested_parcel_in_counties_multiple_max