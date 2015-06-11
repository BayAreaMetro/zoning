ALTER TABLE parcel 
   ALTER COLUMN geom 
   TYPE Geometry(MultiPolygon, 26910) 
   USING ST_Transform(geom, 26910);

CREATE TABLE parcel_invalid AS
SELECT *
FROM parcel
WHERE ST_IsValid(geom) = false;
COMMENT ON TABLE parcel_invalid is 'spandex parcels-invalid geometries';

CREATE TABLE parcel_geometrycollection
AS
SELECT *
FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
COMMENT ON TABLE parcel_geometrycollection is 'spandex parcels-geometrycollection type';
--returns 0 rows

DELETE FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

DELETE FROM parcel 
WHERE ST_IsValid(geom) = false;
COMMENT ON TABLE parcel_invalid is 'spandex parcels-only valid geometries';

create INDEX parcel_geom_id_idx ON parcel using hash (geom_id);
CREATE INDEX parcel_gidx ON parcel USING GIST (geom);
VACUUM (ANALYZE) parcel;