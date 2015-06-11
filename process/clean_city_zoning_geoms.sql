DROP TABLE zoning.cities_towns_valid;
CREATE TABLE zoning.cities_towns_valid AS
SELECT 
	tablename, juris, zoning, ST_MakeValid(the_geom) geom
FROM
	zoning.cities_towns;
COMMENT ON TABLE zoning.cities_towns_valid is 'subset of zoning.cities_towns_source with valid geometries only';

DROP TABLE zoning.cities_towns_invalid;
CREATE TABLE zoning.cities_towns_invalid AS
SELECT *
FROM zoning.cities_towns
WHERE ST_IsValid(the_geom) = false;
COMMENT ON TABLE zoning.cities_towns_invalid is 'subset of zoning.cities_towns_source with invalid geometries only';

DROP TABLE zoning.cities_towns_geometry_collection;
CREATE TABLE zoning.cities_towns_geometry_collection
AS
SELECT *
FROM zoning.cities_towns_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE zoning.geometry_collection is 'subset of zoning.cities_towns_source with non multipolygon geometries produced by makevalid';

DELETE FROM zoning.cities_towns_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';

SELECT UpdateGeometrySRID('zoning','cities_towns_valid','geom',26910);
ALTER TABLE zoning.cities_towns_valid 
 ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 26910);

ALTER TABLE zoning.cities_towns RENAME TO cities_towns_source;
COMMENT ON TABLE zoning.cities_towns_source is 'this is the source merged table of all source city zoning geometries. use zoning.cities_towns_valid for working multipolygons.';
