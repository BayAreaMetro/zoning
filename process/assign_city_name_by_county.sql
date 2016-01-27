DROP SCHEMA parcel_county_views cascade;
CREATE SCHEMA parcel_county_views;
CREATE VIEW parcel_county_views.santa_clara 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 85;
CREATE VIEW parcel_county_views.alameda 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 01;
CREATE VIEW parcel_county_views.contra_costa 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 13;
CREATE VIEW parcel_county_views.san_francisco 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 75;
CREATE VIEW parcel_county_views.san_mateo 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 81;
CREATE VIEW parcel_county_views.sonoma 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 97;
CREATE VIEW parcel_county_views.solano 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 95;
CREATE VIEW parcel_county_views.marin 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 41;
CREATE VIEW parcel_county_views.napa 
AS SELECT geoid10_int, geom_id, point_on_surface from parcel where county_id = 55;

DROP SCHEMA jurisdiction_county_views cascade;
CREATE SCHEMA jurisdiction_county_views;
CREATE VIEW jurisdiction_county_views.santa_clara 
AS SELECT geoid10_int, geom from admin_staging.city10_ba where county = 85;
CREATE VIEW jurisdiction_county_views.alameda 
AS SELECT * from admin_staging.city10_ba where county = 01;
CREATE VIEW jurisdiction_county_views.contra_costa 
AS SELECT * from admin_staging.city10_ba where county = 13;
CREATE VIEW jurisdiction_county_views.san_francisco
AS SELECT * from admin_staging.city10_ba where county = 75;
CREATE VIEW jurisdiction_county_views.san_mateo 
AS SELECT * from admin_staging.city10_ba where county = 81;
CREATE VIEW jurisdiction_county_views.sonoma 
AS SELECT * from admin_staging.city10_ba where county = 97;
CREATE VIEW jurisdiction_county_views.solano 
AS SELECT * from admin_staging.city10_ba where county = 95;
CREATE VIEW jurisdiction_county_views.marin 
AS SELECT * from admin_staging.city10_ba where county = 41;
CREATE VIEW jurisdiction_county_views.napa 
AS SELECT * from admin_staging.city10_ba where county = 55;

UPDATE parcel_county_views.santa_clara upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM 
parcel_county_views.santa_clara p
LEFT JOIN 
jurisdiction_county_views.santa_clara j
ON ST_Contains(j.geom, p.point_on_surface)) as subquery
where subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.alameda upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.alameda p
LEFT JOIN 
jurisdiction_county_views.alameda j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.contra_costa upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.contra_costa p
LEFT JOIN 
jurisdiction_county_views.contra_costa j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.san_francisco upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.san_francisco p
LEFT JOIN 
jurisdiction_county_views.san_francisco j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.san_mateo upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.san_mateo p
LEFT JOIN 
jurisdiction_county_views.san_mateo j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.sonoma upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.sonoma p
LEFT JOIN 
jurisdiction_county_views.sonoma j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.solano upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.solano p
LEFT JOIN 
jurisdiction_county_views.solano j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.marin upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.marin p
LEFT JOIN 
jurisdiction_county_views.marin j
ON ST_Contains(j.geom, p.point_on_surface)) AS subquery
WHERE subquery.geom_id = upd_p.geom_id;

UPDATE parcel_county_views.napa upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int from 
parcel_county_views.napa p 
LEFT JOIN 
jurisdiction_county_views.napa j
ON ST_Contains(j.geom, p.point_on_surface)) as subquery
where subquery.geom_id = upd_p.geom_id;

DROP TABLE IF EXISTS admin_staging.parcels_on_jurisdiction_lines;
CREATE TABLE admin_staging.parcels_on_jurisdiction_lines AS
SELECT juris.name10 as name1,
juris.county as county_bool,
juris.geoid10 geoid,
p.geom_id
FROM
administrative_areas.jurisdictions juris,
parcel p
WHERE
p.geom && juris.boundary_lines AND
ST_Intersects(juris.boundary_lines, p.geom);
COMMENT ON TABLE admin_staging.parcel_counties is 'parcels st_intersect with juris boundaries';

CREATE TABLE admin_staging.parcels_on_jurisdiction_lines_geo AS
SELECT pol.name1 as polyname, pol.county_bool as polcounty, pol.geoid polgeoid, p.geom_id, p.geom
FROM
parcel p,
admin_staging.parcels_on_jurisdiction_lines pol
WHERE
p.geom_id = pol.geom_id;

---------

CREATE INDEX ON admin_staging.parcels_on_jurisdiction_lines_geo using btree (geom_id);
CREATE INDEX ON admin_staging.parcels_on_jurisdiction_lines_geo using gist (geom);

UPDATE administrative_areas.jurisdictions
SET geom = ST_MakeValid(geom);

DROP TABLE IF EXISTS admin_staging.parcels_on_jurisdiction_lines_geo_overlaps;
CREATE TABLE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps AS
select * from GetOverlaps('admin_staging.parcels_on_jurisdiction_lines_geo','administrative_areas.jurisdictions','id','geom') as codes(
        geom_id bigint,
        jurisdiction_table_id double precision,
        area double precision,
        prop double precision,
        geom geometry);

--create primary key
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE admin_staging_parcels_on_jurisdiction_lines_geo_overlaps_id_seq;
UPDATE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps SET id = nextval('admin_staging_parcels_on_jurisdiction_lines_geo_overlaps_id_seq');
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps ALTER COLUMN id SET DEFAULT nextval('admin_staging_parcels_on_jurisdiction_lines_geo_overlaps_id_seq');
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_geo_overlaps ADD PRIMARY KEY (id);



UPDATE parcel
SET geoid10_int = subquery.geoid10_int FROM (
SELECT
p.prop
cast(j.geoid10 AS int) as geoid10_int
FROM
administrative_areas.jurisdictions j,
admin_staging.parcels_on_jurisdiction_lines_geo_overlaps p
WHERE
max(prop)
) subquery


CREATE VIEW admin_staging.resolve_admin_overlap AS
SELECT DISTINCT ON (1)
       geom_id, prop, jurisdiction_table_id
FROM   admin_staging.parcels_on_jurisdiction_lines_geo_overlaps
ORDER  BY 1, 2 DESC, 3;

--in the future, should use geoid10_int as jurisdiction id
--but since above query took so long, just mapping the table id to geoid10_int for now

UPDATE parcel
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.id, p.geom_id FROM
        administrative_areas.jurisdictions j,
        parcel p
        where p.geoid10_int = j.geoid10_int) s
    where s.geom_id=parcel.geom_id;

UPDATE parcel
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.jurisdiction_table_id as id, geom_id FROM
        admin_staging.resolve_admin_overlap j) s
    where s.geom_id=parcel.geom_id;



SELECT
    j.name10,
    s.countof
    from
        (select distinct
            jurisdiction_id,
            count(*) as countof
            from parcel group by jurisdiction_id) s,
        administrative_areas.jurisdictions j
        where j.id = s.jurisdiction_id
    order by (2) asc;





CREATE VIEW admin_staging.parcels_in_counties AS
    SELECT * FROM parcel
    WHERE geoid10_int IS NULL;

UPDATE admin_staging.parcels_in_counties
 SET geoid10_int = 6000 + county_id

UPDATE admin_staging.parcels_in_counties
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.id, p.geom_id FROM
        administrative_areas.jurisdictions j,
        admin_staging.parcels_in_counties p
        where p.geoid10_int = j.geoid10_int) s
    where s.geom_id=parcel.geom_id;

UPDATE parcel p
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.id, p.geom_id
        FROM
        administrative_areas.jurisdictions j,
        (select * from parcel where geoid10_int < 7000) p
        where p.geoid10_int = j.geoid10_int) s
    where p.geom_id = s.geom_id;

CREATE TABLE admin_staging.parcels_jurisdictions as
SELECT p.geom_id, j.name10, j.geoid10, j.county, p.jurisdiction_id
FROM parcel p
LEFT JOIN
administrative_areas.jurisdictions j
ON p.jurisdiction_id = j.id
where j.county = false;

INSERT INTO admin_staging.parcels_jurisdictions
SELECT p.geom_id, j.name10 || ' County', j.geoid10, j.county, p.jurisdiction_id
FROM parcel p
LEFT JOIN
administrative_areas.jurisdictions j
ON p.jurisdiction_id = j.id
where j.county = true;

UPDATE parcel_county_views.santa_clara upd_p
SET geoid10_int = subquery.geoid10_int FROM (
SELECT geom_id, j.geoid10_int FROM
parcel_county_views.santa_clara p
LEFT JOIN
jurisdiction_county_views.santa_clara j
ON ST_Contains(j.geom, p.point_on_surface)) as subquery
where subquery.geom_id = upd_p.geom_id;

UPDATE parcel p
    SET jurisdiction_id = 363
    WHERE geoid10_int = 6075;

select count(*) from parcel where jurisdiction_id is null;

create table nojuris_parcels as
select * from parcel where jurisdiction_id is null;



DROP TABLE IF EXISTS admin_staging.parcels_on_lines_int_count cascade;
CREATE TABLE admin_staging.parcels_on_lines_int_count AS
SELECT geom_id, count(*) as countof FROM
            admin_staging.parcels_on_jurisdiction_lines_geo
            GROUP BY geom_id;
COMMENT ON TABLE admin_staging.parcels_on_lines_int_count is 'count by geom_id of st_intersects of parcel and zoning';

--add table to inspect errors in overlapping areas
DROP INDEX IF EXISTS zoning_parcel_intersection_count_geom_id;
CREATE INDEX zoning_parcel_intersection_count_geom_id ON zoning.parcel_intersection_count (geom_id);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP TABLE IF EXISTS zoning.parcel_intersection_count_geo;
CREATE TABLE zoning.parcel_intersection_count_geo AS
SELECT c.countof, p.geom_id, p.geom from parcel p, zoning.parcel_intersection_count c  where p.geom_id=c.geom_id;
COMMENT ON TABLE zoning.parcel_intersection_count_geo is 'count by geom_id of st_intersects of parcel and zoning with geometry';

ALTER TABLE zoning.parcel_intersection_count_geo ADD PRIMARY KEY (geom_id);

DROP INDEX IF EXISTS zoning_parcel_intersection_count;
CREATE INDEX zoning_parcel_intersection_count ON zoning.parcel_intersection_count (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP VIEW IF EXISTS zoning.parcels_with_multiple_zoning;
CREATE VIEW zoning.parcels_with_multiple_zoning AS
SELECT geom_id, geom from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof>1);
