create INDEX plu06_may2015estimate_gidx ON plu06_may2015estimate using GIST (wkb_geometry);
create INDEX plu06_may2015estimate_idx ON plu06_may2015estimate using hash (objectid);
VACUUM (ANALYZE) plu06_may2015estimate;

alter table plu06_may2015estimate rename column of_ to of;

UPDATE plu06_may2015estimate SET IH = case when IH = '1' then '1' else '0' end;
ALTER TABLE plu06_may2015estimate ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;

ALTER TABLE plu06_may2015estimate ALTER COLUMN juris TYPE INTEGER USING HS::INTEGER;

ALTER TABLE plu06_may2015estimate ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE plu06_may2015estimate ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;

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
	 	ST_Intersection(p.geom, z.wkb_geometry) geom 
	FROM 
		(select geom_id, geom 
			FROM zoning.unmapped_parcels
			WHERE geom_id in 
				(select geom_id 
					from zoning.unmapped_parcel_intersection_count 
					WHERE countof>1)) as p,
				(select objectid, wkb_geometry from plu06_may2015estimate) as z
		WHERE ST_Intersects(z.wkb_geometry, p.geom)
		) f
GROUP BY 
	geom_id,
	plu06_objectid;

DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly_plu;
CREATE TABLE zoning.parcel_overlaps_maxonly_plu AS
SELECT geom_id, plu06_objectid, prop 
FROM zoning.parcel_overlaps_plu WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps_plu
  GROUP BY geom_id
);

delete from zoning.parcel_overlaps_maxonly_plu 
	where geom_id in 
	( select p.geom_id from 
		(SELECT geom_id, count(*) as countof 
			FROM zoning.parcel_overlaps_maxonly_plu GROUP BY geom_id) p 
		WHERE p.countof>1); 

INSERT INTO zoning.parcel_withdetails
SELECT 
9999 as id, 
juris as juris, 
'NA' as city, 
gengplu as name,
-9999 as min_far, 
z.max_height as max_height,
z.max_far as max_far, 
-9999 as min_front_setback,
-9999 as max_front_setback,
-9999 as side_setback,
-9999 as rear_setback,
-9999 as min_dua,
z.max_dua as max_dua,           
-9999 as coverage,          
z.max_du_per as max_du_per_parcel,
-9999 as min_lot_size,      
z.hs,z.ht,z.hm,z.of,z.ho,z.sc,z.il,z.iw,z.ih,z.rs,z.rb,z.mr,z.mt,z.me,
p.geom_id as geom_id,
p.geom as geom
from 
(select * from zoning.unmapped_parcel_zoning_plu
where geom_id in 
(select geom_id 
from zoning.unmapped_parcel_intersection_count 
WHERE countof=1)) as p,
plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

INSERT INTO zoning.parcel_withdetails
SELECT 
9999 as id, 
juris as juris, 
'NA' as city, 
gengplu as name,
-9999 as min_far, 
z.max_height as max_height,
z.max_far as max_far, 
-9999 as min_front_setback,
-9999 as max_front_setback,
-9999 as side_setback,
-9999 as rear_setback,
-9999 as min_dua,
z.max_dua as max_dua,           
-9999 as coverage,          
z.max_du_per as max_du_per_parcel,
-9999 as min_lot_size,      
z.hs,z.ht,z.hm,z.of,z.ho,z.sc,z.il,z.iw,z.ih,z.rs,z.rb,z.mr,z.mt,z.me,
p.geom_id as geom_id,
p.geom as geom
from (select p2.* 
	from zoning.unmapped_parcel_zoning_plu p2,
	zoning.parcel_overlaps_maxonly_plu pmax
	where pmax.geom_id=p2.geom_id AND
	p2.plu06_objectid=pmax.plu06_objectid) as p,
plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;



