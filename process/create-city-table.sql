select m.common_name from
zoning_staging.shapefile_metadata
where county is TRUE;

drop table admin_staging.unioned_counties;
create table admin_staging.unioned_counties as
select cn.geoid10, cn.name10, st_union(cn.geom) as geom from
zoning_staging.shapefile_metadata m,
admin_staging.temp_census cn
where m.county is TRUE
and (cn.name10 like 'Alameda'
or cn.name10 like m.common_name)
group by cn.geoid10,
cn.name10;

create table admin_staging.temp_census as
select m.common_name, mtc.geoid10, census.geo_id, census.geom
from admin_staging.gz_2010_us_050_00_5m census,
admin_staging.county10_ca mtc,
zoning_staging.shapefile_metadata m
where 1=1
AND mtc.geoid10 = right(census.geo_id,5)
AND m.county is TRUE
and mtc.name10 like m.common_name;


UPDATE admin_staging.city10_ba
SET geom = ST_MakeValid(geom);

drop table admin_staging.unincorporated_counties;
CREATE TABLE admin_staging.unincorporated_counties AS
SELECT cnty.geoid10, cnty.name10, ST_Difference(cnty.geom, cty.geom) as geom
FROM admin_staging.unioned_counties cnty,
admin_staging.city10_ba cty;

DROP TABLE admin_staging.unincorporated_counties_geometry_collection;
CREATE TABLE admin_staging.unincorporated_counties_geometry_collection AS
SELECT *
FROM admin_staging.unincorporated_counties
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE admin_staging.unincorporated_counties is 'subset of adming_staging.county with non multipolygon';


UPDATE admin_staging.unincorporated_counties
SET geom = ST_Multi(geom);

drop table admin_staging.unincorporated_counties_union;
CREATE TABLE admin_staging.unincorporated_counties_union AS
SELECT cnty.geoid10, cnty.name10, ST_Union(cnty.geom) as geom
FROM admin_staging.unincorporated_counties cnty
group by cnty.geoid10,
cnty.name10;

DROP TABLE IF EXISTS admin.jurisdictions;
CREATE TABLE admin.jurisdictions AS
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


