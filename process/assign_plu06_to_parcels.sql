DROP TABLE IF EXISTS zoning_staging.parcel_overlaps_maxonly_plu;
CREATE TABLE zoning_staging.parcel_overlaps_maxonly_plu AS
SELECT geom_id, plu06_objectid, prop 
FROM zoning_staging.parcel_overlaps_plu WHERE (geom_id,prop) IN
( SELECT geom_id, MAX(prop)
  FROM zoning_staging.parcel_overlaps_plu
  GROUP BY geom_id 
);

DROP TABLE IF EXISTS zoning_staging.plu06_one_intersection;
CREATE TABLE zoning_staging.plu06_one_intersection AS
SELECT
p.geom_id,
z.origgplu,
'6' || lpad(cast(z.objectid as text),4,'0000') as zoning_id,
100 as prop,
cast('plu06' as text) as tablename,
p.geom
from 
(select * from zoning_staging.unmapped_parcel_zoning_staging_plu
where geom_id in 
(select geom_id 
from zoning_staging.unmapped_parcel_intersection_count
WHERE countof=1)) as p,
zoning_staging.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

create INDEX plu06_one_intersection_gidx ON zoning_staging.plu06_one_intersection using GIST (geom);
vacuum (analyze) zoning_staging.plu06_one_intersection;

DROP TABLE IF EXISTS zoning_staging.plu06_many_intersection;
CREATE TABLE zoning_staging.plu06_many_intersection AS
SELECT
p.geom_id,
z.origgplu,
'6' || lpad(cast(z.objectid as text),4,'0000') as zoning_id,
p.prop,
cast('plu06' as text) as tablename,
p.geom
from (select p2.*, pmax.prop 
	from zoning_staging.unmapped_parcel_zoning_staging_plu p2,
	zoning_staging.parcel_overlaps_maxonly_plu pmax
	where pmax.geom_id=p2.geom_id AND
	p2.plu06_objectid=pmax.plu06_objectid) as p,
zoning_staging.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;
COMMENT ON TABLE zoning_staging.plu06_many_intersection IS 'plu 06 intersection table with selected greatest max value of zoning_staging';

create INDEX plu06_many_intersection_gidx ON zoning_staging.plu06_many_intersection using GIST (geom);
vacuum (analyze) zoning_staging.plu06_one_intersection;

DROP TABLE IF EXISTS zoning_staging.plu06_many_intersection_two_max;
CREATE TABLE zoning_staging.plu06_many_intersection_two_max AS
SELECT * FROM 
zoning_staging.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning_staging.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

--EXPORT pg_dump --table zoning_staging.parcel_withdetails > /mnt/bootstrap/zoning_staging/parcel_withdetails05142015.sql

DELETE FROM 
zoning_staging.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning_staging.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

create INDEX plu06_one_intersection_geomid_idx ON zoning_staging.plu06_one_intersection using hash (geom_id);

VACUUM (ANALYZE) zoning_staging.plu06_one_intersection;

INSERT INTO zoning_staging.parcel
select geom_id, cast(zoning_id as integer), cast(origgplu as text) as zoning_staging, -9999 as juris, prop, tablename
from zoning_staging.plu06_one_intersection
WHERE geom_id NOT IN (SELECT geom_id from zoning_staging.parcel);
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning_staging.parcel;

VACUUM (ANALYZE) zoning_staging.parcel;

create INDEX plu06_many_intersection_geomid_idx ON zoning_staging.plu06_many_intersection using hash (geom_id);

VACUUM (ANALYZE) zoning_staging.plu06_many_intersection;

INSERT INTO zoning_staging.parcel
select geom_id,cast(zoning_id as integer), cast(origgplu as text) as zoning_staging, -9999 as juris, prop, tablename
from zoning_staging.plu06_many_intersection
WHERE geom_id NOT IN (SELECT geom_id from zoning_staging.parcel);
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning_staging.parcel;

VACUUM (ANALYZE) zoning_staging.parcel;