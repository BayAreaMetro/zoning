CREATE VIEW zoning.nozoning_zoning_ids08 AS 
SELECT p.joinnuma, z.id
	FROM zoning.nozoning p
		LEFT JOIN zoning.bayarea_2008 z ON ST_DWithin(p.geom, z.wkb_geometry, 0);
	--ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);

CREATE VIEW zoning.nozoning_zoning_ids12 AS 
SELECT p.joinnuma, z.id
	FROM zoning.nozoning p
		LEFT JOIN zoning.bayarea_2012 z ON ST_DWithin(p.geom, z.wkb_geometry, 0);
	--ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);

ALTER TABLE administrative.places 
	ALTER COLUMN geom 
	TYPE Geometry(Polygon, 26910) 
	USING ST_Transform(geom, 26910);

/*
FASTER QUERY BELOW

CREATE TABLE zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from fewerparcels as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, ST_Transform(n.geom,26910), 0);

*/

CREATE VIEW zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, administrative.places as n 
WHERE NOT ST_Intersects(n.geom, p.geom);

CREATE VIEW zoning.nozoning_parcels_with_place_2008 AS
SELECT p1.joinnuma, p2.name, p2.name_1 p1.id
FROM zoning.nozoning_zoning_ids08 p1
    LEFT JOIN zoning.parcels_in_places p2 ON p1.joinnuma = p2.joinnuma;

CREATE VIEW zoning.nozoning_parcels_with_place_2012 AS
SELECT p1.joinnuma, p2.name, p2.name_1 p1.id
FROM zoning.nozoning_zoning_ids12 p1
    LEFT JOIN zoning.parcels_in_places p2 ON p1.joinnuma = p2.joinnuma;

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

