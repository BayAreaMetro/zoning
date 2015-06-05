CREATE TABLE zoning.parcel_overlaps AS
SELECT 
	geom_id,
	zoning_id,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.geom_id, 
	z.zoning_id, 
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.geom) geom 
FROM (select geom_id, geom FROM zoning.parcels_with_multiple_zoning) as p,
(select zoning_id, geom from zoning.bay_area_generic) as z
WHERE ST_Intersects(z.geom, p.geom)
) f
GROUP BY 
	geom_id,
	zoning_id;

CREATE INDEX zoning_parcel_overlaps_gidx ON zoning.parcel_overlaps USING GIST (geom);
CREATE INDEX zoning_parcel_overlaps_geom_id_idx ON zoning.parcel_overlaps USING hash (geom_id);
CREATE INDEX zoning_parcel_overlaps_zoning_id_idx ON zoning.parcel_overlaps USING hash (zoning_id);

ALTER TABLE zoning.parcel_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_parcel_overlaps_id_seq;
UPDATE zoning.parcel_overlaps  SET id = nextval('zoning_parcel_overlaps_id_seq');
ALTER TABLE zoning.parcel_overlaps ALTER COLUMN id SET DEFAULT nextval('zoning_parcel_overlaps_id_seq');
ALTER TABLE zoning.parcel_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.parcel_overlaps ADD PRIMARY KEY (id);

VACUUM (ANALYZE) zoning.parcel_overlaps;