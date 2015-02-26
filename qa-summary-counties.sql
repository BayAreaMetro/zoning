CREATE VIEW zoning.parcels_in_counties AS
SELECT n.name10, n.countyfp10, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, demographic.county10 as n 
WHERE ST_Intersects(n.geom, p.geom);

CREATE VIEW zoning.nozoning_parcels_with_county_2008 AS
SELECT p1.joinnuma, p1.id, p2.name10 
FROM zoning.nozoning_zoning_ids08 as p1
    LEFT JOIN zoning.parcels_in_counties as p2 ON p1.joinnuma = p2.joinnuma;

CREATE VIEW zoning.nozoning_parcels_with_county_2012 AS
SELECT p1.joinnuma, p1.id, p2.name10
FROM zoning.nozoning_zoning_ids12 as p1
    LEFT JOIN zoning.parcels_in_counties as p2 ON p1.joinnuma = p2.joinnuma;

--count total parcels in places
CREATE VIEW countallparcels_c AS 
SELECT name10, count(*) as ParcelCount from zoning.parcels_in_counties group by name10;

CREATE VIEW countallparcels_cdump AS 
SELECT SELECT name10, 
      count((ST_Dump(zoning.parcels_in_counties.geom)).geom AS geom)
FROM zoning.parcels_in_counties;

--count parcels with no zoning (in original file) within places 
--NEED TO DOUBLE CHECK ON THIS QUERY
CREATE VIEW notinfile_c AS 
SELECT name10, count(*) as NoZoningCount from zoning.nozoning_parcels_with_county_2008 group by name10;

--count parcels with no zoning within places (in original file) within places, which werent' covered by a 2008 zoning id either
CREATE VIEW notinfile_notin2008_c AS 
SELECT name10, count(*) as NotIn2008Count from zoning.nozoning_parcels_with_county_2008 WHERE ID IS NULL group by name10;

CREATE VIEW notinfile_notin2012_c AS 
SELECT name10, count(*) as NotIn2012Count from zoning.nozoning_parcels_with_county_2012 WHERE ID IS NULL group by name10;

SELECT name10, a.ParcelCount, b.NoZoningCount, c.NotIn2008Count, d.NotIn2012Count
FROM countallparcels_cdump AS a
NATURAL JOIN notinfile_c AS b 
NATURAL JOIN notinfile_notin2008_c AS c 
NATURAL JOIN notinfile_notin2012_c AS d; 