create table zoning.parcel_generic_code as
select * from zoning.parcel_withdetails;

--for commercial sites, we need height and FAR
--lets get a count of how many parcels do not have values for both of these by city
/*select city,
	count(*) as countof
	from zoning.parcel_generic_code
WHERE of=1 OR ho=1 OR rs=1 OR rb=1 OR me=1 
AND max_far = 0 OR max_height = 0
group by city;
*/
\COPY (select city, count(*) as countof from zoning.parcel_generic_code WHERE of=1 OR ho=1 OR rs=1 OR rb=1 OR me=1 AND max_far = 0 AND max_height = 0 group by city ORDER BY countof DESC) TO 'commercial_parcels_where_height_or_far_are_zero_by_city.csv' WITH CSV;

--for residential sites, we need dua AND/OR height
--lets get a count of how many parcels do not have values for both of these by city
\COPY (select city, count(*) as countof from zoning.parcel_generic_code WHERE hs=1 OR ht=1 OR hm=1 OR mr=1 AND max_dua = 0 AND max_dua = -9999 AND max_height = 0 group by city ORDER BY countof DESC) TO 'residential_parcels_where_height_or_dua_are_zero_by_city.csv' WITH CSV;

CREATE VIEW zoning.pgc_residential AS
SELECT * FROM zoning.parcel_generic_code
WHERE 
hs=1 OR ht=1 OR hm=1 OR mr=1;

CREATE VIEW zoning.pgc_commercial AS
SELECT * FROM zoning.parcel_generic_code
WHERE 
mr=1 OR mt=1 OR of=1 OR ho=1 OR rb=1 OR rs = 1;

CREATE VIEW zoning.pgc_industrial AS
SELECT * FROM zoning.parcel_generic_code
WHERE 
il=1 OR iw=1 OR ih=1;

\COPY (select city, count(*) as countof, sum(landacres*max_dua) as units from (select city, hs, ht, hm, mr, max_dua, st_area(geom)/4046.86 as landacres from zoning.pgc_residential where max_dua != -9999) a group by city ORDER BY units DESC) TO 'residential_units_by_city_by_type_from_dua.csv' WITH CSV;

\COPY (select city, count(*) as countof, sum(max_du_per_parcel) as units from (select city, hs, ht, hm, mr, max_du_per_parcel, st_area(geom)/4046.86 as landacres from zoning.pgc_residential where max_du_per_parcel != -9999) a group by city ORDER BY units DESC) TO 'residential_units_by_city_by_type_from_du_per_parcel.csv' WITH CSV;

\COPY (select city, count(*), sum(landarea*max_far) as commercial_sqft from (select city, max_far, st_area(geom) as landarea from zoning.pgc_commercial where max_far != -9999) a group by city order by commercial_sqft DESC) TO 'commercial_square_footage_by_city_landarea_x_far.csv' WITH CSV;

\COPY (select city, count(*), sum(landarea*(max_height/10)) as commercial_sqft from (select city, max_height, st_area(geom)*0.7 as landarea from zoning.pgc_commercial where max_height != -9999) a group by city order by commercial_sqft DESC) TO 'commercial_square_footage_by_city_height_by_10_x_area.csv' WITH CSV;

/* these are more readable versions of the 3 copy statements above
select city,
count(*),
sum(landacres*max_dua) as units
from (select city, hs, ht, hm, mr, max_dua,
	st_area(geom)/4046.86 as landacres
	from zoning.pgc_residential
	where max_dua != -9999) a
group by
city;

select city,
count(*),
sum(max_du_per_parcel) as dwellings
from (select city, hs, ht, hm, mr, max_du_per_parcel,
	st_area(geom)/4046.86 as landacres
	from zoning.pgc_residential
	where max_du_per_parcel != -9999) a
group by
city;

select city,
count(*),
sum(landarea*max_far) as commercial_sqft
from (select city, max_far,
	st_area(geom) as landarea
	from zoning.pgc_commercial
	where max_far != -9999)) a
group by
city;

\COPY (select city, count(*), sum(landarea*(max_height/10)) 
as commercial_sqft from (select city, max_height, st_area(geom)*0.7 
as landarea 
from zoning.pgc_commercial where max_height != -9999) a 
group by city order by commercial_sqft DESC) 
TO 'commercial_square_footage_by_city_height_by_10_x_area' WITH CSV;

*/

/*--how many square meters of parcel-land are there in each city
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
city*/

--count of zoning by type combination
\COPY (select distinct(hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me),count(*) from zoning.parcel_generic_code group by hs,ht,hm,of,ho,sc,il,iw,ih,rs,rb,mr,mt,me) TO 'zoning_types_count.csv' WITH CSV; 

--for residential, whats the area of land like?
\COPY (select distinct(hs,ht,hm,mr),city,count(*),sum(landacres*max_dua) as units from (select city, hs, ht, hm, mr, max_dua,st_area(geom)/4046.86 as landacres from zoning.parcel_generic_code) a group by hs,ht,hm,mr,city) TO 'residential_units_by_city_by_type.csv' WITH CSV;
--1 acre = 4046.86

---this is a copy of the above, more readable because \COPY didn't like multiple lines
/*select distinct(of,ho,rs,rb,me),
	city,
	count(*),
	sum(landacres*max_dua),0) as units 
from (select city, hs, ht, hm, mr, max_dua,st_area(geom)/4046.86 as landacres 
	from zoning.parcel_generic_code) a 
group by hs,ht,hm,mr,city) TO 'residential_units_by_city_by_type' WITH CSV;
*/
