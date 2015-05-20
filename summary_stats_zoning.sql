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

