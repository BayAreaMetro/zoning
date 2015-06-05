CREATE TABLE zoning.bay_area AS
SELECT 
	tablename, juris, zoning, ST_MakeValid(the_geom) geom
FROM
	zoning.merged_jurisdictions;

CREATE TABLE zoning.invalid AS
SELECT *
FROM zoning.bay_area
WHERE ST_IsValid(geom) = false;

DELETE FROM zoning.bay_area 
WHERE ST_IsValid(geom) = false;

CREATE TABLE zoning.geometry_collection
AS
SELECT *
FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
--returns 0 rows

DELETE FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

CREATE TABLE zoning.bay_area_generic AS 
SELECT c.id as zoning_id, z.geom FROM
zoning.codes_dictionary c,
zoning.bay_area z
WHERE c.juris=z.juris 
AND c.name = z.zoning;

CREATE INDEX zoning_bay_area_generic_gidx ON zoning.bay_area_generic USING GIST (geom);
CREATE INDEX zoning_bay_area_zoning_id_gidx ON zoning.bay_area_generic USING HASH (zoning_id);
VACUUM (ANALYZE) zoning.bay_area_generic;
