DROP TABLE IF EXISTS zoning.cities_parcel_overlaps;
CREATE TABLE zoning.cities_parcel_overlaps AS
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
				zoning.parcel_contested p1, 
				admin.parcel_cities p2
				where p1.geom_id=p2.geom_id)) as p,
(select zoning_id, tablename, geom from zoning.bay_area_generic) as z
WHERE ST_Intersects(z.geom, p.geom)
) f
GROUP BY 
	geom_id,
	tablename,
	zoning_id;
COMMENT ON TABLE zoning.parcel_overlaps is 'st_intersects with area for contested parcels in cities';

CREATE INDEX zoning_parcel_overlaps_cities_gidx ON zoning.cities_parcel_overlaps USING GIST (geom);
CREATE INDEX zoning_parcel_overlaps_cities_geom_id_idx ON zoning.cities_parcel_overlaps USING hash (geom_id);
CREATE INDEX zoning_parcel_overlaps_cities_zoning_id_idx ON zoning.cities_parcel_overlaps USING hash (zoning_id);

ALTER TABLE zoning.cities_parcel_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_parcel_overlaps_cities_id_seq;
UPDATE zoning.cities_parcel_overlaps  SET id = nextval('zoning_parcel_overlaps_cities_id_seq');
ALTER TABLE zoning.cities_parcel_overlaps ALTER COLUMN id SET DEFAULT nextval('zoning_parcel_overlaps_cities_id_seq');
ALTER TABLE zoning.cities_parcel_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.cities_parcel_overlaps ADD PRIMARY KEY (id);

VACUUM (ANALYZE) zoning.cities_parcel_overlaps;