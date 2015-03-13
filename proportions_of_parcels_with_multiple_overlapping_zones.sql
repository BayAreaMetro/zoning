CREATE TABLE zoning.parcels_source_2012_overlaps AS
SELECT 
	joinnuma,
	ogc_fid,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (SELECT p.joinnuma, z.ogc_fid, ST_Area(p.geom) parcelarea, ST_Intersection(p.geom, z.geom) geom --does p.id need to be unique or should be joinnuma?
		FROM
		zoning_legacy_2012.lookup z, 
		zoning.auth_geo p
      	WHERE ST_Intersects(p.geom, z.geom) 
      	AND
      	(SELECT count(*) FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, p.geom))>1
      	) foo
GROUP BY joinnuma, ogc_fid;