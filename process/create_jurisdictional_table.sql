---
/*
We need to select and combine from the 2 tables below, which are
from legacy data. 

All we need in this case is: the columnd in the shapefile_metadata, 
the fips codes, and the geometries. 

sf_bayarea_landuse=> \d zoning_staging.shapefile_metadata 
     Table "zoning_staging.shapefile_metadata"
         Column          |     Type     | Modifiers 
-------------------------+--------------+-----------
 juris_id                | integer      | not null
 shapefile_name          | text         | 
 common_name             | text         | 
 collection_project_year | numeric(4,0) | 
 regulation_type         | text         | 
 year_in_tablename       | numeric(4,0) | 
 county                  | boolean      | 
Indexes:
    "juris_id_pk" PRIMARY KEY, btree (juris_id)


                                          Table "admin_staging.city10_ba"
   Column   |             Type             |                           Modifiers                           
------------+------------------------------+---------------------------------------------------------------
 gid        | integer                      | not null default nextval('admin.city10_ba_gid_seq'::regclass)
 statefp10  | character varying(2)         | 
 placefp10  | character varying(5)         | 
 placens10  | character varying(8)         | 
 geoid10    | character varying(7)         | 
 name10     | character varying(100)       | 
 namelsad10 | character varying(100)       | 
 lsad10     | character varying(2)         | 
 classfp10  | character varying(2)         | 
 pcicbsa10  | character varying(1)         | 
 pcinecta10 | character varying(1)         | 
 mtfcc10    | character varying(5)         | 
 funcstat10 | character varying(1)         | 
 intptlat10 | character varying(11)        | 
 intptlon10 | character varying(12)        | 
 gisjoin    | character varying(10)        | 
 ba         | smallint                     | 
 inc        | smallint                     | 
 county     | smallint                     | 
 eejcat     | smallint                     | 
 predev     | smallint                     | 
 vital_cat  | character varying(25)        | 
 aland10int | numeric(10,0)                | 
 awater10in | numeric(10,0)                | 
 geom       | geometry(MultiPolygon,26910) | 
Indexes:
    "city10_ba_pkey" PRIMARY KEY, btree (gid)
    "city10_ba_geom_idx" gist (geom)

*/

DROP TABLE IF EXISTS admin_staging.unincorporated_counties;

CREATE TABLE admin_staging.unincorporated_counties AS
SELECT cnty.geoid10,
       cnty.name10,
       ST_DifferenceAgg(ST_MakeValid(cnty.geom), ST_MakeValid(cty.geom)) AS geom
FROM
  (SELECT *
   FROM admin_staging.county10_ca
   WHERE geoid10 IN ('06085',
                     '06001',
                     '06013',
                     '06075',
                     '06081',
                     '06097',
                     '06095',
                     '06041',
                     '06055')) cnty,
     admin_staging.city10_ba cty
GROUP BY cnty.geoid10,
         cnty.name10;


DROP TABLE IF EXISTS administrative_areas.jurisdictions;


CREATE TABLE administrative_areas.jurisdictions AS
SELECT m.juris_id,
       m.shapefile_name,
       m.collection_project_year,
       m.regulation_type,
       m.year_in_tablename,
       m.county,
       c.geoid10,
       c.name10,
       c.geom
FROM zoning_staging.shapefile_metadata m,
     admin_staging.city10_ba c
WHERE 1=1
  AND m.county = FALSE
  AND c.name10 LIKE m.common_name;


INSERT INTO administrative_areas.jurisdictions (shapefile_name, collection_project_year, regulation_type, year_in_tablename, county, geoid10, name10, geom)
SELECT m.shapefile_name AS shapefile_name,
       '2012' AS collection_project_year,
       'gp' regulation_type,
            0 AS year_in_tablename,
            'true' AS county,
            c.geoid10 AS geoid10,
            c.name10 AS name10,
            c.geom AS geom
FROM admin_staging.unincorporated_counties c
INNER JOIN
  (SELECT *
   FROM zoning_staging.shapefile_metadata
   WHERE county = TRUE) m ON c.name10 LIKE m.common_name;


DROP VIEW IF EXISTS admin_staging.cities_to_fill_with_2006;


CREATE VIEW admin_staging.cities_to_fill_with_2006 AS
SELECT name10,
       geoid10,
       geom
FROM
  (SELECT cty.geoid10,
          cty.name10,
          cty.geom,
          j.juris_id
   FROM admin_staging.city10_ba cty
   LEFT JOIN administrative_areas.jurisdictions j ON cty.geoid10 = j.geoid10) q
WHERE q.juris_id IS NULL;


INSERT INTO administrative_areas.jurisdictions (shapefile_name, collection_project_year, regulation_type, year_in_tablename, county, geoid10, name10, geom)
SELECT 'plu_may2015estimate.shp' AS shapefile_name,
       '2006' AS collection_project_year,
       'na' regulation_type,
            0 AS year_in_tablename,
            'false' AS county,
            c.geoid10 AS geoid10,
            c.name10 AS name10,
            c.geom AS geom
FROM admin_staging.cities_to_fill_with_2006 c;


DROP VIEW IF EXISTS admin_staging.counties_to_fill_with_2006;


CREATE VIEW admin_staging.counties_to_fill_with_2006 AS
SELECT name10,
       geoid10,
       geom
FROM
  (SELECT cnty.geoid10,
          cnty.name10,
          cnty.geom,
          j.juris_id
   FROM admin_staging.unincorporated_counties cnty
   LEFT JOIN administrative_areas.jurisdictions j ON cnty.geoid10 = j.geoid10
   WHERE county IS NULL
     AND NOT cnty.geoid10 = '06075' -- san francisco
) q
WHERE q.juris_id IS NULL;


INSERT INTO administrative_areas.jurisdictions (shapefile_name, collection_project_year, regulation_type, year_in_tablename, county, geoid10, name10, geom)
SELECT 'plu_may2015estimate.shp' AS shapefile_name,
       '2006' AS collection_project_year,
       'na' regulation_type,
            0 AS year_in_tablename,
            'true' AS county,
            c.geoid10 AS geoid10,
            c.name10 AS name10,
            c.geom AS geom
FROM admin_staging.counties_to_fill_with_2006 c;

--create primary key
ALTER TABLE administrative_areas.jurisdictions ADD COLUMN id INTEGER;
CREATE SEQUENCE administrative_areas_jurisdictions_id_seq;
UPDATE administrative_areas.jurisdictions SET id = nextval('administrative_areas_jurisdictions_id_seq');
ALTER TABLE administrative_areas.jurisdictions ALTER COLUMN id SET DEFAULT nextval('administrative_areas_jurisdictions_id_seq');
ALTER TABLE administrative_areas.jurisdictions ALTER COLUMN id SET NOT NULL;
ALTER TABLE administrative_areas.jurisdictions ADD PRIMARY KEY (id);

ALTER TABLE administrative_areas.jurisdictions
    ADD COLUMN geoid10_int integer;

UPDATE administrative_areas.jurisdictions
    SET geoid10_int = cast(geoid10 as integer);

DROP INDEX IF EXISTS administrative_areas_jurisdictions_geoid_idx;
CREATE INDEX administrative_areas_jurisdictions_geoid_idx ON administrative_areas.jurisdictions using btree (geoid10_int);

--create spatial index
DROP INDEX IF EXISTS administrative_areas_jurisdictions_idx;
CREATE INDEX administrative_areas_jurisdictions_idx ON administrative_areas.jurisdictions using gist (geom);


ALTER TABLE administrative_areas.jurisdictions
    ADD COLUMN boundary_lines geometry(MULTILINESTRING,26910);

UPDATE administrative_areas.jurisdictions
    SET boundary_lines = ST_Boundary(juris.geom)::geometry(MULTILINESTRING,26910)

DROP INDEX IF EXISTS admin_staging_jurisdictions_lines;
    CREATE INDEX admin_staging_jurisdictions_lines ON administrative_areas.jurisdictions using gist (boundary_lines);

VACUUM (ANALYZE) administrative_areas.jurisdictions;
