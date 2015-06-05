DROP TABLE IF EXISTS zoning.parcel_in_counties;
CREATE TABLE zoning.parcel_in_counties AS
SELECT p2n.geom_id, p2n.zoning_id, p2n.city, cb.name10 as countyname1, p2n.geom 
FROM 
	(SELECT c.city, p2.geom_id, p2.zoning_id, p2.geom
	FROM
	zoning.codes_dictionary c,
	zoning.parcel_two_max_not_in_cities p2
	WHERE c.id = p2.zoning_id) p2n,
	admin.county10_ca cb
WHERE ST_Intersects(cb.geom,p2n.geom);
--Query returned successfully: 50561 rows affected, 2052 ms execution time.

DROP TABLE IF EXISTS zoning.temp_parcel_county_table;
CREATE TABLE zoning.temp_parcel_county_table AS
SELECT * from 
zoning.parcel_in_counties p
WHERE 
regexp_replace(city, 'Unincorporated ','') = countyname1;
--Total query runtime: 2414 ms. -- 25403 rows retrieved.

create INDEX zoning_temp_parcel_county_table_geomid_idx ON zoning.temp_parcel_county_table using hash (geom_id);

/*
COPY PARCELS WITHIN MULTIPLE CITIES 
AND PARCELS WITHIN MULTIPLE COUNTIES 
TO A SEPARATE TABLE, AND THEN REMOVE 
THEM FROM THE PARCEL/ZONING MAPPING
BECAUSE WE CANNOT ASSIGN THEM 
ONLY 1 ZONING TYPE USING THE RULE 
BASED ON WHICH JURISDICTION THEY ARE LOCATED IN
*/

/*CREATE TABLE zoning.parcels_in_multiple_cities AS
SELECT * FROM zoning.parcel_in_cities WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.parcel_in_cities
GROUP BY geom_id) p
WHERE p.countof>1);*/
--Query returned successfully: 3121 rows affected, 3337 ms execution time.

CREATE TABLE zoning.parcels_in_multiple_counties AS
SELECT * FROM zoning.temp_parcel_county_table WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.temp_parcel_county_table
GROUP BY geom_id) p
WHERE p.countof>1);

\COPY zoning.parcels_in_multiple_cities TO '/zoning_data/parcels_in_multiple_cities.csv' DELIMITER ',' CSV HEADER;
--https://mtcdrive.box.com/shared/static/uumadei43eqxl5ll90fdtqz7nxhhg711.csv;

\COPY zoning.parcels_in_multiple_counties TO '/zoning_data/parcels_in_multiple_counties.csv' DELIMITER ',' CSV HEADER;
--https://mtcdrive.box.com/shared/static/ouya6lylpd4e1z5vqfz2gngebkmgfkur.csv;

DELETE FROM zoning.temp_parcel_county_table WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.temp_parcel_county_table
GROUP BY geom_id) p
WHERE p.countof>1);
--Query returned successfully: 712 rows affected, 65 ms execution time.
