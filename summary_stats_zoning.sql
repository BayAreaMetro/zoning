--how many square meters of parcel-land are there in each city
select
st_area(geom)
from
zoning.parcel_generic_code
group by
city

--how many square meters of land/parcel are there in each city
select
st_area(geom)/count(geom_id)
from
zoning.parcel_generic_code
group by
city

--count of zoning by type combination
select distinct(hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me),
count(*)
from zoning.parcel_generic_code
group by
hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me) TO 'zoning_types_count' 

--for residential, whats the area of land like?
select distinct(hs,ht,hm,mr),
city,
count(*),
sum(landacres*max_dua) as units
from (select city, hs, ht, hm, mr, max_dua,
	st_area(geom)/4046.86 as landacres
	from zoning.parcel_generic_code) a
group by
hs,ht,hm,mr,city;

--1 acre = 4046.86


