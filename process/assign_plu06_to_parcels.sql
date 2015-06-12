/*DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly_plu;
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
		WHERE p.countof>1); */

DROP TABLE IF EXISTS zoning.plu06_one_intersection; 
CREATE TABLE zoning.plu06_one_intersection AS
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
zoning.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

create INDEX plu06_one_intersection_gidx ON zoning.plu06_one_intersection using GIST (geom);
vacuum (analyze) zoning.plu06_one_intersection;

DROP TABLE IF EXISTS zoning.plu06_many_intersection;
CREATE TABLE zoning.plu06_many_intersection AS
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
zoning.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

create INDEX plu06_many_intersection_gidx ON zoning.plu06_many_intersection using GIST (geom);
vacuum (analyze) zoning.plu06_one_intersection;
/*
--EXPORT pg_dump --table zoning.parcel_withdetails > /mnt/bootstrap/zoning/parcel_withdetails05142015.sql
CREATE TABLE zoning.parcel_withdetails_nogeom AS
SELECT
id,                
juris,             
city,              
name,              
min_far,           
max_far,           
max_height,        
min_front_setback, 
max_front_setback, 
side_setback,      
rear_setback,      
min_dua,           
max_dua,           
coverage,          
max_du_per_parcel, 
min_lot_size,      
hs,                
ht,                
hm,                
of,                
ho,                
sc,                
il,                
iw,                
ih,                
rs,                
rb,                
mr,                
mt,                
me,                
geom_id
FROM zoning.parcel_withdetails;
\COPY zoning.parcel_withdetails_nogeom TO '/mnt/bootstrap/zoning/zoning_parcels_with_details.csv' DELIMITER ',' CSV HEADER;
DROP TABLE zoning.parcel_withdetails_nogeom;*/