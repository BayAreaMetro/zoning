select m.common_name from
zoning_staging.shapefile_metadata
where county is TRUE;

drop table admin_staging.unincorporated_counties;
CREATE TABLE admin_staging.unincorporated_counties AS
SELECT cnty.geoid10, cnty.name10, ST_DifferenceAgg(ST_MakeValid(cnty.geom), ST_MakeValid(cty.geom)) as geom
FROM
(SELECT *
    FROM admin_staging.county10_ca
    where geoid10 in
    ('06085','06001','06013',
        '06075','06081','06097',
        '06095','06041','06055')) cnty,
admin_staging.city10_ba cty
group by
cnty.geoid10,
cnty.name10;

DROP TABLE IF EXISTS administrative_areas.jurisdictions;
CREATE TABLE administrative_areas.jurisdictions AS
SELECT m.*, c.geoid10, c.name10, c.geom
from zoning_staging.shapefile_metadata m,
admin_staging.city10_ba c
WHERE 1=1
    AND m.county = false
    AND c.name10 like m.common_name;

INSERT INTO administrative_areas.jurisdictions
        (shapefile_name,
        common_name,
        collection_project_year,
        regulation_type,
        year_in_tablename,
        county,
        geoid10,
        name10,
        geom)
    select
        m.shapefile_name as shapefile_name,
        c.name10 as common_name,
        '2012' as collection_project_year,
        'gp' regulation_type,
        0 as year_in_tablename,
        'true' as county,
        c.geoid10 as geoid10,
        c.name10 as name10,
        c.geom as geom
    from admin_staging.unincorporated_counties c
    INNER JOIN
        (select * from zoning_staging.shapefile_metadata
            where county = true) m
    ON c.name10 LIKE m.common_name;

drop view admin_staging.cities_to_fill_with_2006;
create view admin_staging.cities_to_fill_with_2006 as
select name10, geoid10, geom
from
(SELECT cty.geoid10, cty.name10, cty.geom, j.juris_id
from admin_staging.city10_ba cty
left join administrative_areas.jurisdictions j
on
cty.geoid10 = j.geoid10) q
WHERE q.juris_id IS NULL;

INSERT INTO administrative_areas.jurisdictions
        (shapefile_name,
        common_name,
        collection_project_year,
        regulation_type,
        year_in_tablename,
        county,
        geoid10,
        name10,
        geom)
    select
        'plu_may2015estimate.shp' as shapefile_name,
        c.name10 as common_name,
        '2006' as collection_project_year,
        'na' regulation_type,
        0 as year_in_tablename,
        'false' as county,
        c.geoid10 as geoid10,
        c.name10 as name10,
        c.geom as geom
    from admin_staging.cities_to_fill_with_2006 c;

drop view admin_staging.counties_to_fill_with_2006;
create view admin_staging.counties_to_fill_with_2006 as
select name10, geoid10, geom
from
(SELECT cnty.geoid10, cnty.name10, cnty.geom, j.juris_id
from admin_staging.unincorporated_counties cnty
left join administrative_areas.jurisdictions j
on
cnty.geoid10 = j.geoid10
where county is null
and not cnty.geoid10 = '06075'
) q
WHERE q.juris_id IS NULL;

INSERT INTO administrative_areas.jurisdictions
        (shapefile_name,
        common_name,
        collection_project_year,
        regulation_type,
        year_in_tablename,
        county,
        geoid10,
        name10,
        geom)
    select
        'plu_may2015estimate.shp' as shapefile_name,
        c.name10 as common_name,
        '2006' as collection_project_year,
        'na' regulation_type,
        0 as year_in_tablename,
        'true' as county,
        c.geoid10 as geoid10,
        c.name10 as name10,
        c.geom as geom
    from admin_staging.counties_to_fill_with_2006 c;



/*
create table admin_staging.temp_census as
select m.common_name, mtc.geoid10, census.geo_id, census.geom
from admin_staging.gz_2010_us_050_00_5m census,
admin_staging.county10_ca mtc,
zoning_staging.shapefile_metadata m
where 1=1
AND mtc.geoid10 = right(census.geo_id,5)
AND m.county is TRUE
and mtc.name10 like m.common_name;

drop table admin_staging.temp_census_places;
create table admin_staging.temp_census_places as
select m.common_name, mtc.geoid10, census.geo_id, census.geom
from admin_staging.gz_2010_06_160_00_500k census,
admin_staging.city10_ba mtc,
zoning_staging.shapefile_metadata m
where 1=1
AND mtc.geoid10 = right(census.geo_id,7)
AND census.state like '06';
*/

UPDATE admin_staging.city10_ba
SET geom = ST_MakeValid(geom);

/*drop table admin_staging.unincorporated_counties;
CREATE TABLE admin_staging.unincorporated_counties AS
SELECT cnty.geoid10, cnty.common_name, ST_DifferenceAgg(cnty.geom, cty.geom) as geom
FROM admin_staging.temp_census cnty,
admin_staging.temp_census_places cty
group by cnty.geoid10,
cnty.common_name;
*/



DROP TABLE admin_staging.unincorporated_counties_geometry_collection;
CREATE TABLE admin_staging.unincorporated_counties_geometry_collection AS
SELECT *
FROM admin_staging.unincorporated_counties
WHERE GeometryType(geom) <> 'MULTIPOLYGON';
COMMENT ON TABLE admin_staging.unincorporated_counties is 'subset of adming_staging.county with non multipolygon';



drop table admin_staging.unincorporated_counties;
CREATE TABLE admin_staging.unincorporated_counties AS
SELECT cnty.geoid10, cnty.common_name, ST_DifferenceAgg(cnty.geom, cty.geom) as geom
FROM admin_staging.temp_census cnty,
admin_staging.temp_census_places cty
group by cnty.geoid10,
cnty.common_name;



UPDATE admin_staging.unincorporated_counties
SET geom = ST_Multi(geom);

drop table admin_staging.unincorporated_counties_union;
CREATE TABLE admin_staging.unincorporated_counties_union AS
SELECT cnty.geoid10, cnty.common_name, ST_Union(cnty.geom) as geom
FROM admin_staging.unincorporated_counties cnty
group by cnty.geoid10,
cnty.common_name;

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


