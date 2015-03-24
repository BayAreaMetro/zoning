CREATE TABLE zoning.lookup_new_valid AS
SELECT 
	ogc_fid, tablename, zoning, juris, ST_MakeValid(geom) geom
FROM
	zoning.lookup_new;

CREATE TABLE zoning.lookup_2012_problem_geoms2 as
SELECT *
FROM zoning.lookup_new_valid
WHERE st_isempty(st_centroid(geom));

DELETE FROM zoning.lookup_new_valid
WHERE st_isempty(st_centroid(geom));

INSERT INTO zoning.lookup_2012_problem_geoms2 (
SELECT *
FROM zoning.lookup_new_valid
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION');

DELETE FROM zoning.lookup_new_valid
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
