/*DROP TABLE zoning.plu06_may2015estimate_valid;
CREATE TABLE zoning.plu06_may2015estimate_valid AS
SELECT 
	juris, zoning, ST_MakeValid(geom) geom
FROM
	zoning.plu06_may2015estimate;
COMMENT ON TABLE zoning.plu06_may2015estimate_valid is 'subset of zoning.plu06_may2015estimate_source with valid geometries only';
*/

DROP TABLE zoning.plu06_may2015estimate_invalid;
CREATE TABLE zoning.plu06_may2015estimate_invalid AS
SELECT *
FROM zoning.plu06_may2015estimate
WHERE ST_IsValid(geom) = false;
COMMENT ON TABLE zoning.plu06_may2015estimate_invalid is 'subset of zoning.plu06_may2015estimate_source with invalid geometries only';

UPDATE zoning.plu06_may2015estimate
	SET geom = ST_MakeValid(geom);

DROP TABLE zoning.plu06_may2015estimate_geometry_collection;
CREATE TABLE zoning.plu06_may2015estimate_geometry_collection AS 
SELECT *
FROM zoning.plu06_may2015estimate
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE zoning.geometry_collection is 'subset of zoning.plu06_may2015estimate with non multipolygon geometries produced by makevalid';

DELETE FROM zoning.plu06_may2015estimate
WHERE GeometryType(geom) <> 'MULTIPOLYGON';

ALTER TABLE zoning.plu06_may2015estimate
 ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 26910);