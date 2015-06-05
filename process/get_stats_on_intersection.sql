CREATE TABLE zoning.parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning.parcel_intersection
			GROUP BY geom_id;

CREATE INDEX zoning_parcel_intersection_count ON zoning.parcel_intersection_count (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP VIEW IF EXISTS zoning.parcels_with_multiple_zoning;
CREATE VIEW zoning.parcels_with_multiple_zoning AS
SELECT geom_id, geom from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof>1);

#add table to inspect errors in overlapping areas
CREATE INDEX zoning_parcel_intersection_count_geom_id ON zoning.parcel_intersection_count (geom_id);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

CREATE TABLE zoning.parcel_intersection_count_geo AS
SELECT c.countof, p.geom_id, p.geom from parcel2 p, zoning.parcel_intersection_count c  where p.geom_id=c.geom_id

ALTER TABLE zoning.parcel_intersection_count_geo ADD PRIMARY KEY (geom_id);
