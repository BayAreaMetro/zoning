create INDEX plu06_may2015estimate_gidx ON plu06_may2015estimate using GIST (wkb_geometry);
VACUUM (ANALYZE) plu06_may2015estimate;
--USE PLU 2006 WHERE NO OTHER DATA AVAILABLE

DROP TABLE IF EXISTS zoning.unmapped_parcel_zoning_plu;
CREATE TABLE zoning.unmapped_parcel_zoning_plu AS
SELECT p.geom_id, p.geom, z.OBJECTID as plu06_objectid
FROM zoning.unmapped_parcels p,
public.plu06_may2015estimate z 
WHERE ST_Intersects(z.wkb_geometry,p.geom);

DROP TABLE IF EXISTS zoning.unmapped_parcel_intersection_count;
CREATE TABLE zoning.unmapped_parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning.unmapped_parcel_zoning_plu
			GROUP BY geom_id;

DROP TABLE IF EXISTS zoning.parcel_overlaps_plu 
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
	 	ST_Intersection(p.geom, z.wkb_geometry) geom 
	FROM 
		(select geom_id, geom 
			FROM zoning.unmapped_parcels
			WHERE geom_id in 
				(select geom_id 
					from zoning.unmapped_parcel_intersection_count 
					WHERE countof>1)) as p,
				(select origgplu, wkb_geometry from plu06_may2015estimate) as z
		WHERE ST_Intersects(z.wkb_geometry, p.geom)
		) f
GROUP BY 
	geom_id,
	origgplu;

CREATE TABLE zoning.parcel_withdetails_test
AS SELECT * from zoning.parcel_withdetails;

INSERT INTO zoning.parcel_withdetails_test
p.geom_id, -9999 as zoning_id,
p.hs,p.ht,p.hm,p.of,p.ho,p.sc,p.il,p.iw,p.ih,p.rs,p.rb,p.mr,p.mt,p.me,
p.max_far,p.max_height,p.max_dua,
p.max_du_per as max_du_per_parcel
/*min_far,p.min_front_setback,p.max_front_setback,
p.side_setback,p.rear_setback,p.min_dua,p.coverage,
p.min_lot_size*/
from 
(select geom_id 
from zoning.unmapped_parcel_intersection_count 
WHERE countof=1) as p