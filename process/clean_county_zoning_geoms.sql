DROP TABLE zoning.unincorporated_counties_valid;
CREATE TABLE zoning.unincorporated_counties_valid AS
SELECT 
	tablename, juris, zoning, ST_MakeValid(the_geom) geom
FROM
	zoning.unincorporated_counties;
COMMENT ON TABLE zoning.unincorporated_counties_valid is 'subset of zoning.unincorporated_counties_source with valid geometries only';

DROP TABLE zoning.unincorporated_counties_invalid;
CREATE TABLE zoning.unincorporated_counties_invalid AS
SELECT *
FROM zoning.unincorporated_counties
WHERE ST_IsValid(the_geom) = false;
COMMENT ON TABLE zoning.unincorporated_counties_invalid is 'subset of zoning.unincorporated_counties_source with invalid geometries only';

DROP TABLE zoning.unincorporated_counties_geometry_collection;
CREATE TABLE zoning.unincorporated_counties_geometry_collection
AS
SELECT *
FROM zoning.unincorporated_counties_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE zoning.geometry_collection is 'subset of zoning.unincorporated_counties_source with non multipolygon geometries produced by makevalid';

DELETE FROM zoning.unincorporated_counties_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';

SELECT UpdateGeometrySRID('zoning','unincorporated_counties_valid','geom',26910);
ALTER TABLE zoning.unincorporated_counties_valid 
 ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 26910);

--ALTER TABLE zoning.unincorporated_counties RENAME TO unincorporated_counties_source;
COMMENT ON TABLE zoning.unincorporated_counties is 'this is the source merged table of all source city zoning geometries. use zoning.unincorporated_counties_valid for working multipolygons.';
