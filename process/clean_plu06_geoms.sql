create INDEX plu06_may2015estimate_gidx ON zoning_staging.plu06_may2015estimate using GIST (geom);
create INDEX plu06_may2015estimate_idx ON zoning_staging.plu06_may2015estimate using hash (objectid);
VACUUM (ANALYZE) zoning_staging.plu06_may2015estimate;

ALTER TABLE zoning_staging.plu06_may2015estimate RENAME COLUMN of_ TO of;

ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;

ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN juris TYPE INTEGER USING HS::INTEGER;

ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning_staging.plu06_may2015estimate ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;

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