DROP TABLE zoning.bay_area;
CREATE TABLE zoning.bay_area AS
SELECT 
	tablename, juris, zoning, ST_MakeValid(the_geom) geom
FROM
	zoning.merged_jurisdictions;
COMMENT ON TABLE zoning.bay_area is 'subset of zoning.merged_jurisdictions with valid geometries only';

DROP TABLE zoning.invalid ;
CREATE TABLE zoning.invalid AS
SELECT *
FROM zoning.bay_area
WHERE ST_IsValid(geom) = false;
SELECT UpdateGeometrySRID('zoning','bay_area','geom',26910);
COMMENT ON TABLE zoning.invalid is 'subset of zoning.merged_jurisdictions with invalid geometries only';

DELETE FROM zoning.bay_area 
WHERE ST_IsValid(geom) = false;

DROP TABLE zoning.geometry_collection ;
CREATE TABLE zoning.geometry_collection AS
SELECT *
FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
COMMENT ON TABLE zoning.geometry_collection is 'subset of zoning.merged_jurisdictions with geometry collection geometries only';

DELETE FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';