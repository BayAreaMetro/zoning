DROP TABLE IF EXISTS zoning_staging.unmapped_parcel_zoning_staging_plu;
CREATE TABLE zoning_staging.unmapped_parcel_zoning_staging_plu AS
SELECT p.geom_id, p.geom, z.OBJECTID as plu06_objectid
FROM zoning_staging.parcel_contested3 p,
zoning_staging.plu06_may2015estimate z
WHERE z.geom && p.geom AND ST_Intersects(z.geom,p.geom);

DROP TABLE IF EXISTS zoning_staging.unmapped_parcel_intersection_count;
CREATE TABLE zoning_staging.unmapped_parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning_staging.unmapped_parcel_zoning_staging_plu
			GROUP BY geom_id;
