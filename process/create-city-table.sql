DROP TABLE IF EXISTS admin.cities;
CREATE TABLE admin.cities AS 
SELECT m.*, c.geoid10, c.geom
from zoning_staging.shapefile_metadata m,
admin_staging.city10_ba c
WHERE 1=1 
    AND c.name10 like m.common_name
    AND m.county is FALSE;

--check on which tables from metadata were not loaded to cities
--8, with san francisco going to the city table
select m.common_name from 
zoning_staging.shapefile_metadata m 
where m.juris_id not in 
(select juris_id from admin.cities);

select name10 from 
admin_staging.city10_ba
where geoid10 not in 
(select geoid10 from admin.cities);


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


