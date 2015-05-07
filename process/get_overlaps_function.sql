CREATE OR REPLACE FUNCTION zoning.get_overlaps(zoning_tbl table,parcels_tbl table)
  RETURNS table AS
$BODY$
DECLARE
	--need to declare table?
	--declare zoning, parcels tables?
BEGIN
	RETURN SELECT 
		geom_id,
		zoning_id,
		sum(ST_Area(geom)) area,
		round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
		ST_Union(geom) geom
	FROM (
	SELECT p.geom_id, 
		z.zoning_id, 
	 	ST_Area(p.geom) parcelarea, 
	 	ST_Intersection(p.geom, z.geom) geom 
	FROM (select geom_id, geom FROM parcels_tbl) as p,
	(select zoning_id, geom from zoning_tbl) as z
	WHERE ST_Intersects(z.geom, p.geom)
	) f
	GROUP BY 
		geom_id,
		zoning_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

