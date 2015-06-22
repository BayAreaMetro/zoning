DROP TABLE IF EXISTS zoning.parcel_intersection_count cascade;
CREATE TABLE zoning.parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning.parcel_intersection
			GROUP BY geom_id;
COMMENT ON TABLE zoning.parcel_intersection_count is 'count by geom_id of st_intersects of parcel and zoning';

--add table to inspect errors in overlapping areas
DROP INDEX IF EXISTS zoning_parcel_intersection_count_geom_id;
CREATE INDEX zoning_parcel_intersection_count_geom_id ON zoning.parcel_intersection_count (geom_id);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP TABLE IF EXISTS zoning.parcel_intersection_count_geo;
CREATE TABLE zoning.parcel_intersection_count_geo AS
SELECT c.countof, p.geom_id, p.geom from parcel p, zoning.parcel_intersection_count c  where p.geom_id=c.geom_id;
COMMENT ON TABLE zoning.parcel_intersection_count_geo is 'count by geom_id of st_intersects of parcel and zoning with geometry';

ALTER TABLE zoning.parcel_intersection_count_geo ADD PRIMARY KEY (geom_id);

CREATE INDEX zoning_parcel_intersection_count ON zoning.parcel_intersection_count (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count;