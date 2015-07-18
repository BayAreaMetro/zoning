DROP TABLE IF EXISTS zoning.parcel_intersection;
CREATE TABLE zoning.parcel_intersection AS
SELECT z.zoning, z.juris, p.geom_id,z.zoning_id, 100 as prop, z.tablename as tablename FROM
	(select zoning.get_id(zoning,juris) as zoning_id, zoning, juris, tablename, geom from zoning.bay_area) AS z, 
	(select geom_id, geom from parcel) AS p
WHERE p.geom && z.geom AND
ST_Intersects(p.geom,z.geom);
COMMENT ON TABLE zoning.parcel_intersection is 'st_intersects of parcels and zoning.bay_area';