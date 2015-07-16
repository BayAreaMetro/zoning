DROP TABLE IF EXISTS zoning.counties_parcel_overlaps;
CREATE TABLE zoning.counties_parcel_overlaps AS
SELECT 
	geom_id,
	zoning_id,
	tablename,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.geom_id, 
	z.zoning_id,
	z.tablename,
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.geom) geom 
FROM (select geom_id, geom 
		FROM parcel where geom_id in 
			(select p1.geom_id from 
				zoning.parcel_contested2 p1, 
				admin.parcel_counties p2
				where p1.geom_id=p2.geom_id)) as p,
(select zoning.get_id(zoning,juris) as zoning_id, tablename, geom from zoning.unincorporated_counties_valid) as z
WHERE ST_Intersects(z.geom, p.geom)
) f
GROUP BY 
	geom_id,
	tablename,
	zoning_id;
COMMENT ON TABLE zoning.counties_parcel_overlaps is 'st_intersects with area for contested parcels in counties';

DROP INDEX IF EXISTS zoning_parcel_overlaps_counties_gidx;
DROP INDEX IF EXISTS zoning_parcel_overlaps_counties_geom_id_idx;
DROP INDEX IF EXISTS zoning_parcel_overlaps_counties_zoning_id_idx;
CREATE INDEX zoning_parcel_overlaps_counties_gidx ON zoning.counties_parcel_overlaps USING GIST (geom);
CREATE INDEX zoning_parcel_overlaps_counties_geom_id_idx ON zoning.counties_parcel_overlaps USING hash (geom_id);
CREATE INDEX zoning_parcel_overlaps_counties_zoning_id_idx ON zoning.counties_parcel_overlaps USING hash (zoning_id);

ALTER TABLE zoning.counties_parcel_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_parcel_overlaps_counties_id_seq;
UPDATE zoning.counties_parcel_overlaps  SET id = nextval('zoning_parcel_overlaps_counties_id_seq');
ALTER TABLE zoning.counties_parcel_overlaps ALTER COLUMN id SET DEFAULT nextval('zoning_parcel_overlaps_counties_id_seq');
ALTER TABLE zoning.counties_parcel_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.counties_parcel_overlaps ADD PRIMARY KEY (id);

VACUUM (ANALYZE) zoning.counties_parcel_overlaps;