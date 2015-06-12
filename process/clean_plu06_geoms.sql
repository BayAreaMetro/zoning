DROP TABLE zoning.plu06_may2015estimate_valid;
CREATE TABLE zoning.plu06_may2015estimate_valid AS
SELECT 
	tablename, juris, zoning, ST_MakeValid(geom) geom
FROM
	zoning.plu06_may2015estimate;
COMMENT ON TABLE zoning.plu06_may2015estimate_valid is 'subset of zoning.plu06_may2015estimate_source with valid geometries only';

DROP TABLE zoning.plu06_may2015estimate_invalid;
CREATE TABLE zoning.plu06_may2015estimate_invalid AS
SELECT *
FROM zoning.plu06_may2015estimate
WHERE ST_IsValid(geom) = false;
COMMENT ON TABLE zoning.plu06_may2015estimate_invalid is 'subset of zoning.plu06_may2015estimate_source with invalid geometries only';

DROP TABLE zoning.plu06_may2015estimate_geometry_collection;
CREATE TABLE zoning.plu06_may2015estimate_geometry_collection
AS
SELECT *
FROM zoning.plu06_may2015estimate_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE zoning.geometry_collection is 'subset of zoning.plu06_may2015estimate_source with non multipolygon geometries produced by makevalid';

DELETE FROM zoning.plu06_may2015estimate_valid
WHERE GeometryType(geom) <> 'MULTIPOLYGON';

SELECT UpdateGeometrySRID('zoning','plu06_may2015estimate_valid','geom',26910);
ALTER TABLE zoning.plu06_may2015estimate_valid 
 ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 26910);

ALTER TABLE zoning.plu06_may2015estimate RENAME TO plu06_may2015estimate_source;
COMMENT ON TABLE zoning.plu06_may2015estimate_source is 'use zoning.plu06_may2015estimate_valid for working multipolygons.';
