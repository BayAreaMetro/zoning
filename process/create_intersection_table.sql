CREATE TABLE zoning.parcel_intersection AS
SELECT p.geom_id,z.zoning_id FROM
	(select zoning_id, geom from zoning.bay_area_generic) AS z, 
	(select geom_id, geom from parcel) AS p
WHERE p.geom && z.geom AND
ST_Intersects(p.geom,z.geom);