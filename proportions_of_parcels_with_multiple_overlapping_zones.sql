CREATE TABLE zoning.lookup_2012_valid AS
SELECT 
	ogc_fid, tablename, ST_MakeValid(geom)
FROM
	zoning_legacy_2012.lookup;

CREATE TABLE zoning.parcels_source_2012_overlaps AS
SELECT 
	parcel_id,
	ogc_fid,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (SELECT p.parcel_id, z.ogc_fid, ST_Area(p.geom) parcelarea, ST_Intersection(p.geom, z.st_makevalid) geom --does p.id need to be unique or should be joinnuma?
		FROM
		zoning.lookup_2012_valid z, 
		parcel p
      	WHERE (SELECT count(*) FROM
			zoning.lookup_2012_valid as z, parcel p
			WHERE ST_Intersects(z.st_makevalid, p.geom))>1
      	) foo
GROUP BY parcel_id, ogc_fid;