DROP TABLE zoning_staging.plu06_may2015estimate_invalid;
CREATE TABLE zoning_staging.plu06_may2015estimate_invalid AS
SELECT *
FROM zoning_staging.plu06_may2015estimate
WHERE ST_IsValid(geom) = false;
COMMENT ON TABLE zoning_staging.plu06_may2015estimate_invalid is 'subset of zoning_staging.plu06_may2015estimate_source with invalid geometries only';

UPDATE zoning_staging.plu06_may2015estimate
	SET geom = ST_MakeValid(geom);

DROP TABLE zoning_staging.plu06_may2015estimate_geometry_collection;
CREATE TABLE zoning_staging.plu06_may2015estimate_geometry_collection AS
SELECT *
FROM zoning_staging.plu06_may2015estimate
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE zoning_staging.geometry_collection is 'subset of zoning_staging.plu06_may2015estimate with non multipolygon geometries produced by makevalid';

DELETE FROM zoning_staging.plu06_may2015estimate
WHERE GeometryType(geom) <> 'MULTIPOLYGON';

ALTER TABLE zoning_staging.plu06_may2015estimate
 ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 26910);