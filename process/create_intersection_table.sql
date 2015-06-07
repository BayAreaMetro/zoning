CREATE TABLE zoning.parcel_intersection AS
SELECT p.geom_id,z.zoning_id, 100 as prop, z.tablename as tablename FROM
	(select zoning_id, tablename, geom from zoning.bay_area_generic) AS z, 
	(select geom_id, geom from parcel) AS p
WHERE p.geom && z.geom AND
ST_Intersects(p.geom,z.geom);
COMMENT ON TABLE zoning.parcel is 'parcel/zoning intersection output table';