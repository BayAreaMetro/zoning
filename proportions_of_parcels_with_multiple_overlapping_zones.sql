ALTER TABLE parcel 
   ALTER COLUMN geom 
   TYPE Geometry(MultiPolygon, 26910) 
   USING ST_Transform(geom, 26910);

-- Can't fix messed up parcel geoms
-- update parcel
--   SET geom=ST_MakeValid(geom);
--   WHERE ST_IsValid(geom) = false;
-- ABOVE FAILS WITH ERROR:
-- Geometry type (GeometryCollection) does not match column type (MultiPolygon)
-- Parcels may be an unecessarily complex geographic unit
-- Look into using raster?

CREATE TABLE zoning.lookup_2012_valid AS
SELECT 
	ogc_fid, tablename, ST_MakeValid(geom) geom
FROM
	zoning_legacy_2012.lookup;

CREATE INDEX lookup_2012_valid_gidx ON zoning.lookup_2012_valid USING GIST (geom);

CREATE TABLE zoning.lookup_2012_problem_geoms as
SELECT *
FROM zoning.lookup_2012_valid
WHERE st_isempty(st_centroid(geom));

CREATE TABLE parcel_invalid AS
SELECT *
FROM parcel
WHERE ST_IsValid(geom) = false;

CREATE TABLE parcel_valid as 
SELECT * FROM parcel
WHERE ST_IsValid(geom) = true;

INSERT INTO zoning.lookup_2012_problem_geoms (
SELECT *
FROM zoning.lookup_2012_valid
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION')

DELETE FROM zoning.lookup_2012_valid
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

DELETE FROM zoning.lookup_2012_valid
WHERE st_isempty(st_centroid(geom));

CREATE TABLE zoning.parcels_with_multiple_zoning AS
SELECT * from parcel where parcel_id
IN (SELECT parcel_id FROM (SELECT parcel_id, count(*) as countof FROM
			zoning.lookup_2012_valid as z, parcel p
			WHERE ST_Intersects(z.geom, p.geom)
			GROUP BY parcel_id
			) a WHERE countof>1)

-- COULD ALSO CACHE THE FOLLOWING, OR COMBINE WITH ABOVE 
-- e.g. (select *, intersection from parcel,zoning)
--
-- CREATE TABLE pz AS
-- SELECT *, ST_Intersection(z.geom,p.geom) FROM
-- 		zoning.lookup_2012_valid as z, parcel p
-- 		WHERE ST_Intersects(z.geom, p.geom)

CREATE TABLE zoning.pmz_parcel_invalid AS
SELECT *
FROM zoning.parcels_with_multiple_zoning
WHERE ST_IsValid(geom) = false;

DELETE FROM zoning.parcels_with_multiple_zoning
WHERE ST_IsValid(geom) = false;

CREATE TABLE zoning.parcel_overlaps AS
SELECT 
	parcel_id,
	ogc_fid,
	tablename,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.parcel_id, 
	z.ogc_fid, 
	z.tablename,
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.geom) geom
FROM zoning.parcels_with_multiple_zoning p,
zoning.lookup_2012_valid as z
WHERE ST_Intersects(z.geom, p.geom) f
) f
GROUP BY 
	parcel_id,
	ogc_fid,
	tablename;