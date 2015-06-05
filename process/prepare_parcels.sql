ALTER TABLE parcel 
   ALTER COLUMN geom 
   TYPE Geometry(MultiPolygon, 26910) 
   USING ST_Transform(geom, 26910);

CREATE TABLE parcel_invalid AS
SELECT *
FROM parcel
WHERE ST_IsValid(geom) = false;

CREATE TABLE parcel_geometrycollection
AS
SELECT *
FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
--returns 0 rows

DELETE FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

DELETE FROM parcel 
WHERE ST_IsValid(geom) = false;

create INDEX parcel_geom_id_idx ON parcel using hash (geom_id);
CREATE INDEX parcel_gidx ON parcel USING GIST (geom);
VACUUM (ANALYZE) parcel;