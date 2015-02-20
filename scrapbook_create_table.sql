SELECT count(*) FROM zoning.nozoning_zoning_ids WHERE id IS NULL;
--~5000
SELECT count(*) FROM zoning.nozoning_zoning_ids12 WHERE id IS NULL;
--~52478
SELECT count(*) FROM zoning.nozoning_water_ids WHERE id IS NULL;

/*
produce a table with these headers this:
county name, jurisdiction name, # parcels without zoning, # polygons without zoning, # polygons that don't overlap 2012 zoning gdb, # polygons that don't overlap with 2008 gdb 
*/
CREATE TABLE nozoning_parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from zoning.nozoning as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, ST_Transform(n.geom,26910), 0);

--next:need to join the above selection to name, which is county name. 
--ran into problem that can't group by jurisdiction name(name_1) and also county name and get both back. 
--but later, should be able to use NIL values in join to fill in county parcels that are not in jurisdictions
--therefore, unincorporated county parcels
--because spatial join is expensive, doing that now, store, and will do count later. 
--also, might need to run the queries on whether parcels are in old zoning blocks again
SELECT n.name_1, count(p.geom) from zoning.nozoning as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, n.geom, 0) GROUP BY n.name_1;

DROP TABLE zoning.parcels_in_places;
CREATE TABLE zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from fewerparcels as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, ST_Transform(n.geom,26910), 0);

SELECT n.name, n.name_1, p.joinnuma, p.geom from fewerparcels as p,
administrative.places as n WHERE 
ST_CONTAINS(ST_Transform(n.geom,26910),p.geom)

 ALTER TABLE administrative.places 
   ALTER COLUMN geom 
   TYPE Geometry(Point, 32644) 
   USING ST_Transform(geom, 32644);

CREATE TABLE zoning.parcels_not_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, administrative.places as n 
WHERE NOT ST_Intersects(n.geom, p.geom);

CREATE TABLE zoning.parcels_not_in_places AS
SELECT p1.joinnuma, p1.geom
FROM parcels_mpg p1
    LEFT JOIN zoning.parcels_in_places p2 ON p1.joinnuma = p2.joinnuma
WHERE p2.joinnuma IS NULL

--create table of parcels without zoning that were in legacy data, by year, with the geographic area they are in
CREATE TABLE zoning.nozoning_parcels_with_place_2012 AS
SELECT p1.joinnuma, p2.name, p2.name_1 p1.id
FROM zoning.nozoning_zoning_ids12 p1
    LEFT JOIN zoning.parcels_in_places p2 ON p1.joinnuma = p2.joinnuma;

--count total parcels in counties
SELECT name_1, count(*) from zoning.parcels_in_places group by name_1;


--count total parcels in places
CREATE VIEW countallparcels AS 
SELECT name, count(*) as ParcelCount from zoning.parcels_in_places group by name;

--count parcels with no zoning (in original file) within places 
--NEED TO DOUBLE CHECK ON THIS QUERY
CREATE VIEW notinfile AS 
SELECT name, count(*) as NoZoningCount from zoning.nozoning_parcels_with_place_2008 group by name;

--count parcels with no zoning within places (in original file) within places, which werent' covered by a 2008 zoning id either
CREATE VIEW notinfile_notin2008 AS 
SELECT name, count(*) as NotIn2008Count from zoning.nozoning_parcels_with_place_2008 WHERE ID IS NULL group by name;

CREATE VIEW notinfile_notin2012 AS 
SELECT name, count(*) as NotIn2012Count from zoning.nozoning_parcels_with_place_2012 WHERE ID IS NULL group by name;

SELECT name, a.ParcelCount, b.NoZoningCount, c.NotIn2008Count, d.NotIn2012Count
FROM countallparcels as a
NATURAL JOIN notinfile as b 
NATURAL JOIN notinfile_notin2008 as c 
NATURAL JOIN notinfile_notin2012 as d; 