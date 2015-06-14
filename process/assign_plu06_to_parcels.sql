DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly_plu;
CREATE TABLE zoning.parcel_overlaps_maxonly_plu AS
SELECT geom_id, plu06_objectid, prop 
FROM zoning.parcel_overlaps_plu WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps_plu
  GROUP BY geom_id 
);

DROP TABLE IF EXISTS zoning.plu06_one_intersection; 
CREATE TABLE zoning.plu06_one_intersection AS
SELECT 
9999 as id, 
juris as juris, 
text 'NA' as city,
text 'plu06' as tablename,
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
text 'NA' as city,
text 'PLU06' as tablename,
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
COMMENT ON TABLE zoning.plu06_many_intersection IS 'plu 06 intersection table with selected greatest max value of zoning'

create INDEX plu06_many_intersection_gidx ON zoning.plu06_many_intersection using GIST (geom);
vacuum (analyze) zoning.plu06_one_intersection;

DROP TABLE IF EXISTS zoning.plu06_many_intersection_two_max;
CREATE TABLE zoning.plu06_many_intersection_two_max AS
SELECT * FROM 
zoning.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

--EXPORT pg_dump --table zoning.parcel_withdetails > /mnt/bootstrap/zoning/parcel_withdetails05142015.sql

DELETE FROM 
zoning.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

DROP TABLE IF EXISTS zoning.parcel_withdetails;
CREATE TABLE zoning.parcel_withdetails AS
z.id, 
z.juris, 
z.city,
z.tablename,
z.name,
z.min_far, 
z.max_height,
z.max_far, 
z.min_front_setback,
z.max_front_setback,
z.side_setback,
z.rear_setback,
z.min_dua,
z.max_dua,           
z.coverage,          
z.max_du_per_parcel,
z.min_lot_size,      
z.hs,z.ht,z.hm,z.of,z.ho,z.sc,z.il,z.iw,z.ih,z.rs,z.rb,z.mr,z.mt,z.me,
p.geom_id as geom_id,
p.geom as geom
FROM zoning.parcel pz,
zoning.codes_dictionary z,
parcel p
WHERE pz.zoning_id = z.id AND p.geom_id = pz.geom_id;

CREATE INDEX zoning_parcel_withdetails_gidx ON zoning.parcel_withdetails using GIST (geom);
CREATE INDEX zoning_parcel_withdetails_geom_idx ON zoning.parcel_withdetails using hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_withdetails;

INSERT INTO zoning.parcel_withdetails
select * from zoning.plu06_one_intersection;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel_withdetails;

INSERT INTO zoning.parcel_withdetails
select * from zoning.plu06_many_intersection;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel_withdetails;
