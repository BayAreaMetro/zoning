create table zoning.parcel_generic_code as
select * from zoning.parcel_withdetails;

--for commercial sites, we need height and FAR
--lets get a count of how many parcels do not have values for both of these by city
/*select city,
	count(*)
	from zoning.parcel_generic_code
WHERE of=1 OR ho=1 OR rs=1 OR rb=1 OR me=1 
AND max_far = 0 OR max_height = 0
group by city) TO 'commercial_parcels_where_height_or_far_are_zero_by_city' WITH CSV;
*/
\COPY (select city, count(*) from zoning.parcel_generic_code WHERE of=1 OR ho=1 OR rs=1 OR rb=1 OR me=1 AND max_far = 0 OR max_height = 0 group by city) TO 'commercial_parcels_where_height_or_far_are_zero_by_city' WITH CSV;

--for residential sites, we need dua AND/OR height
--lets get a count of how many parcels do not have values for both of these by city
\COPY (select city, count(*) from zoning.parcel_generic_code WHERE hs=1 OR ht=1 OR hm=1 OR mr=1 AND max_dua = 0 OR max_dua = -9999 or max_height = 0 group by city) TO 'residential_parcels_where_height_or_dua_are_zero_by_city' WITH CSV;

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
\COPY (select distinct(hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me),count(*) from zoning.parcel_generic_code group by hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me) TO 'zoning_types_count'; 

--for residential, whats the area of land like?
\COPY (select distinct(hs,ht,hm,mr),city,count(*),sum(landacres*max_dua),0) as units from (select city, hs, ht, hm, mr, max_dua,st_area(geom)/4046.86 as landacres from zoning.parcel_generic_code) a group by hs,ht,hm,mr,city) TO 'residential_units_by_city_by_type' WITH CSV;
--1 acre = 4046.86

---this is a copy of the above, more readable because \COPY didn't like multiple lines
select distinct(of,ho,rs,rb,me),
	city,
	count(*),
	sum(landacres*max_dua),0) as units 
from (select city, hs, ht, hm, mr, max_dua,st_area(geom)/4046.86 as landacres 
	from zoning.parcel_generic_code) a 
group by hs,ht,hm,mr,city) TO 'residential_units_by_city_by_type' WITH CSV;

