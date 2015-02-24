CREATE TABLE zoning.nozoning_zoning_ids12 AS 
SELECT p.joinnuma, z.id
	FROM zoning.nozoning p
		LEFT JOIN zoning.bayarea_2012 z ON ST_DWithin(p.geom, z.wkb_geometry, 0);
	--ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);

CREATE TABLE zoning.nozoning_zoning_ids AS 
SELECT p.joinnuma, z.id
	FROM zoning.nozoning p
		LEFT JOIN zoning.bayarea_2008 z ON ST_Intersects(p.geom, z.wkb_geometry, 0);
	--ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);

CREATE TABLE zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, administrative.places as n 
WHERE ST_Intersects(n.geom, p.geom);

CREATE TABLE zoning.parcels_not_in_places AS
SELECT p1.joinnuma, p1.geom
FROM parcels_mpg p1
    LEFT JOIN zoning.parcels_in_places p2 ON p1.joinnuma = p2.joinnuma
WHERE p2.joinnuma IS NULL

place_name parcels in2008 in2012 

SELECT name, count(*) from zoning.parcels_in_places group by name;

CREATE VIEW count_parcels_in_places_without_zoning AS
SELECT p1.name, p1.joinnuma, p2.joinnuma as p2jna
FROM zoning.parcels_in_places p1
    LEFT JOIN zoning.nozoning_zoning_ids p2 ON p1.joinnuma = p2.joinnuma;

SELECT name, count(p2jna) count_parcels_in_places_without_zoning from WHERE p2jna IS NULL;

SELECT name, count(*) from zoning.parcels_in_places group by name;



