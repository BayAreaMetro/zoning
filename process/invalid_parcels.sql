CREATE TABLE parcel_invalid AS
SELECT *
FROM parcel
WHERE ST_IsValid(geom) = false;

DELETE FROM parcel
WHERE ST_IsValid(geom) = false;

/*Can't fix messed up parcel geoms*/
/*update parcel
  SET geom=ST_MakeValid(geom);
  WHERE ST_IsValid(geom) = false;*/
/*ABOVE FAILS WITH ERROR:
Geometry type (GeometryCollection) does not match column type (MultiPolygon)
but this returns 0 rows:
CREATE TABLE parcel_geometrycollection
AS
SELECT *
FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
--returns 0 rows
*/
