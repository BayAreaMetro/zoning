create view auth_double_parcels 
as select a.parcel_id, a.countOf, b.zoning_id 
FROM (
	select parcel_id, count(*) 
	as countOf from zoning.parcels_auth 
	GROUP BY parcel_id) a 
	INNER JOIN zoning.parcels_auth as b 
	ON b.parcel_id = a.parcel_id 
	WHERE a.countOf>1;

select * from auth_double_parcels;

CREATE TABLE zoning.auth_geo AS
SELECT p2.joinnuma, p1.zoning_id, p2.geom
FROM zoning.parcels_auth as p1
    RIGHT JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;

create view auth_geo_double_parcels 
	as select a.joinnuma, a.countOf 
	FROM (select joinnuma, count(*) 
		as countOf 
		from zoning.auth_geo 
		GROUP BY joinnuma) a 
	WHERE a.countOf>1;

CREATE VIEW zoning.double_parcels_geo 
AS SELECT p1.joinnuma, p2.geom
FROM auth_geo_double_parcels as p1
    LEFT JOIN 
    public.parcels_mpg as p2 
    ON p1.joinnuma = p2.joinnuma;

CREATE TABLE zoning.auth_parcels_doubled_with_placename 
AS SELECT n.name, p.joinnuma, p.geom 
FROM zoning.double_parcels_geo as p, 
administrative.places_jason as n 
WHERE ST_Intersects(n.the_geom, p.geom);
select name, count(*) 
from zoning.auth_parcels_doubled_with_placename 
group by name;

--Check against base parcel data

CREATE VIEW zoning.parcels_notin_auth AS
SELECT p1.parcel_id, p2.joinnuma
FROM zoning.parcels_auth as p1
    RIGHT JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;
SELECT count(*) FROM zoning.parcels_notin_auth WHERE parcel_id IS NULL;

CREATE VIEW zoning.parcels_notin_auth_geo AS
SELECT p1.parcel_id, p2.joinnuma, p2.geom
FROM zoning.parcels_auth as p1
    RIGHT JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;

CREATE TABLE zoning.parcels_notin_auth_with_placename AS
SELECT n.name, p.parcel_id, p.geom 
FROM zoning.parcels_notin_auth_geo as p, administrative.places_jason as n 
WHERE ST_Intersects(n.the_geom, p.geom);