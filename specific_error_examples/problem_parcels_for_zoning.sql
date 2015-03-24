Edge Cases/Problem Parcels for Zoning

select * from zoning.parcels_overlaps,
WHERE parcel_id = 425772

---(is the same geom as:)
select * from zoning.auth_geo 
WHERE joinnuma= 1371357

/*
the problem is that proportion of this parcel doesn't seem to make sense
it falls wholly within 1 zoning type, 
yet the propertion of the intersection of the parcel with zoning 
over the whole parcel area is just .04 

this is possible because the parcel area is much greater than the zoning area for every piece of zoning within the parcel and the question we ask for proportion is:   

round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,

where geom is:

ST_Intersection(p.geom, z.geom) geom
(the intersection area of a parcel (p) and the source zoning geometry(z).)

in the source zoning data, zoning is assigned to individual parcels, 
and in spandex, these parcels geoms were all merged together into one. 
the collection original parcels that were merged into one can be seen with:
*/

select mpg.* 
FROM public.parcel spdx,
public.parcels_mpg mpg
WHERE ST_INTERSECTS(mpg.geom,spdx.geom) 
AND spdx.parcel_id = 425772;

/*
is it possible that this kind of exception will result in erronous 
zoning data when assign zoning to a parcel based 
on the largest proportion of zoning area for that parcel? 

next, we check on that result for this particular parcel:
*/