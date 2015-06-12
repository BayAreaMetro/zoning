DROP TABLE IF EXISTS zoning.parcel_overlaps_plu;
CREATE TABLE zoning.parcel_overlaps_plu AS
SELECT 
	geom_id,
	plu06_objectid,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
	SELECT p.geom_id, 
		z.OBJECTID as plu06_objectid, 
	 	ST_Area(p.geom) parcelarea, 
	 	ST_Intersection(p.geom, z.geom) geom 
	FROM 
		(select geom_id, geom 
			FROM zoning.contested3
			WHERE geom_id in 
				(select geom_id 
					from zoning.unmapped_parcel_intersection_count 
					WHERE countof>1)) as p,
				(select objectid, geom from zoning.plu06_may2015estimate) as z
		WHERE ST_Intersects(z.geom, p.geom)
		) f
GROUP BY 
	geom_id,
	plu06_objectid;
