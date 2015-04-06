select name from zoning.codes_base2012 where city like '%Richmond%'
select distinct gp_des_txt from zoning_legacy_2012.richmond_genplan;

--looks like the wrong lookup field was being used -- for the future, changed this in the load script in load-generic-zoning-code.sql table
--for now, need to load the richmond data and intwersect with parcels

create table zoning.tmp_richmond as 
select a.geom_id, z.id as zoning_id, -99
from
zoning.codes_base2012 z,
(select p.geom_id, r.lu_code
from
public.parcel p,
zoning_legacy_2012.richmond_genplan r
where st_intersects(p.geom,r.wkb_geometry)) a
where a.lu_code = z.name
--Query returned successfully: 40245 rows affected, 3352 ms execution time.

select count(geom_id) - count(distinct geom_id) from zoning.tmp_richmond
--9620 doubles! @#&@#$#!

CREATE TABLE zoning.richmond_doubles AS
SELECT * FROM  zoning.tmp_richmond WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning. zoning.tmp_richmond
GROUP BY geom_id) p
WHERE p.countof>1)
--several thousand parcels with doubles - removing for now will have to resolve later

DELETE FROM zoning.tmp_richmond
	WHERE geom_id in (
		select geom_id from zoning.richmond_doubles);

insert into zoning.parcel
	SELECT * FROM
	zoning.tmp_richmond;