DROP TABLE IF EXISTS admin_staging.parcels_on_lines_int_count cascade;
CREATE TABLE admin_staging.parcels_on_lines_int_count AS
SELECT geom_id, count(*) as countof FROM
            admin_staging.parcels_on_jurisdiction_lines_geo
            GROUP BY geom_id;
COMMENT ON TABLE admin_staging.parcels_on_lines_int_count is 'count by geom_id of st_intersects of parcel and zoning';

--add table to inspect errors in overlapping areas
DROP INDEX IF EXISTS zoning_parcel_intersection_count_geom_id;
CREATE INDEX zoning_parcel_intersection_count_geom_id ON zoning.parcel_intersection_count (geom_id);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP TABLE IF EXISTS zoning.parcel_intersection_count_geo;
CREATE TABLE zoning.parcel_intersection_count_geo AS
SELECT c.countof, p.geom_id, p.geom from parcel p, zoning.parcel_intersection_count c  where p.geom_id=c.geom_id;
COMMENT ON TABLE zoning.parcel_intersection_count_geo is 'count by geom_id of st_intersects of parcel and zoning with geometry';

ALTER TABLE zoning.parcel_intersection_count_geo ADD PRIMARY KEY (geom_id);

DROP INDEX IF EXISTS zoning_parcel_intersection_count;
CREATE INDEX zoning_parcel_intersection_count ON zoning.parcel_intersection_count (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP VIEW IF EXISTS zoning.parcels_with_multiple_zoning;
CREATE VIEW zoning.parcels_with_multiple_zoning AS
SELECT geom_id, geom from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof>1);

