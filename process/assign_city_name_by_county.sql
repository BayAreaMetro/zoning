/*
ALTER TABLE parcel
    ADD COLUMN geoid10 integer;

ALTER TABLE admin_staging.city10_ba
    ADD COLUMN geoid10_int integer;

UPDATE admin_staging.city10_ba
    SET geoid10_int = cast(geoid10 as integer);

ALTER TABLE parcel
    ADD COLUMN geoid10_int integer;

UPDATE parcel
    SET geoid10_int = cast(geoid10 as integer);

ALTER TABLE parcel
    ADD COLUMN point_on_surface geometry(POINT,26910);

ALTER TABLE parcel 
    SET COLUMN point_on_surface = ST_PointOnSurface(geom);

DROP INDEX IF EXISTS parcel_pos_idx;
    CREATE INDEX parcel_pos_idx ON parcel using gist (point_on_surface);

VACUUM (ANALYZE) parcel;

CREATE INDEX ON parcel using btree (geoid10_int);
CREATE INDEX ON admin_staging.city10_ba using gist (geoid10_int);

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
*/

DROP TABLE IF EXISTS admin_staging.parcels_on_jurisdiction_lines;
CREATE TABLE admin_staging.parcels_on_jurisdiction_lines AS
SELECT juris.name10 as name1,
juris.county as county_bool,
juris.geoid10 geoid,
p.geom_id,
p.geom
FROM
admin_staging.jurisdictions juris,
parcel p
WHERE
p.geom && juris.boundary_lines AND
ST_Intersects(juris.boundary_lines, p.geom);
COMMENT ON TABLE admin_staging.parcel_counties is 'parcels st_intersect with juris boundaries';

---------

CREATE INDEX ON admin_staging.parcels_on_jurisdiction_lines using btree (geom_id);
CREATE INDEX ON admin_staging.parcels_on_jurisdiction_lines using gist (geom);

UPDATE admin_staging.jurisdictions
SET geom = ST_MakeValid(geom);

DROP TABLE IF EXISTS admin_staging.parcels_on_jurisdiction_lines_overlaps;
CREATE TABLE admin_staging.parcels_on_jurisdiction_lines_overlaps AS
select * from GetOverlaps('admin_staging.parcels_on_jurisdiction_lines','admin_staging.jurisdictions','id','geom') as codes(
        geom_id bigint,
        jurisdiction_table_id double precision,
        area double precision,
        prop double precision,
        geom geometry);

--create primary key for above
--this might not be necessary
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE admin_staging_parcels_on_jurisdiction_lines_overlaps_id_seq;
UPDATE admin_staging.parcels_on_jurisdiction_lines_overlaps SET id = nextval('admin_staging_parcels_on_jurisdiction_lines_overlaps_id_seq');
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_overlaps ALTER COLUMN id SET DEFAULT nextval('admin_staging_parcels_on_jurisdiction_lines_overlaps_id_seq');
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE admin_staging.parcels_on_jurisdiction_lines_overlaps ADD PRIMARY KEY (id);


--select the jurisdiction that has the
--largest area of coverage for a given parcel
CREATE VIEW admin_staging.resolve_admin_overlap AS
SELECT DISTINCT ON (1)
       geom_id, prop, jurisdiction_table_id
FROM   admin_staging.parcels_on_jurisdiction_lines_overlaps
ORDER  BY 1, 2 DESC, 3;

--in the future, should use geoid10_int as jurisdiction id
--but since above query took so long, just mapping the table id to geoid10_int for now

UPDATE parcel
SET jurisdiction_id = s.id FROM (
SELECT
    j.id, p.geom_id FROM
    admin_staging.jurisdictions j,
    parcel p
where p.geoid10_int = j.geoid10_int) s
where s.geom_id=parcel.geom_id;

UPDATE parcel
SET jurisdiction_id = s.id FROM (
SELECT
    j.jurisdiction_table_id as id, geom_id FROM
    admin_staging.resolve_admin_overlap j) s
where s.geom_id=parcel.geom_id;

CREATE VIEW admin_staging.parcels_in_counties AS
    SELECT * FROM parcel
    WHERE geoid10_int IS NULL;

UPDATE admin_staging.parcels_in_counties
 SET geoid10_int = 6000 + county_id

/*
--admin_staging.parcels_in_counties should be
an empty view because of above

UPDATE admin_staging.parcels_in_counties
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.id, p.geom_id FROM
        admin_staging.jurisdictions j,
        admin_staging.parcels_in_counties p
        where p.geoid10_int = j.geoid10_int) s
    where s.geom_id=parcel.geom_id;

*/

UPDATE parcel p
    SET jurisdiction_id = s.id FROM (
        SELECT
        j.id, p.geom_id
        FROM
        admin_staging.jurisdictions j,
        (select * from parcel where geoid10_int < 7000) p
        where p.geoid10_int = j.geoid10_int) s
    where p.geom_id = s.geom_id;

--prepare output tables for urbansim csv
CREATE TABLE admin_staging.parcels_jurisdictions as
SELECT p.geom_id, j.name10, j.geoid10, j.county, p.jurisdiction_id
FROM parcel p
LEFT JOIN
admin_staging.jurisdictions j
ON p.jurisdiction_id = j.id
where j.county = false;

INSERT INTO admin_staging.parcels_jurisdictions
SELECT p.geom_id, j.name10 || ' County', j.geoid10, j.county, p.jurisdiction_id
FROM parcel p
LEFT JOIN
admin_staging.jurisdictions j
ON p.jurisdiction_id = j.id
where j.county = true;

UPDATE parcel p
    SET jurisdiction_id = 363
    WHERE geoid10_int = 6075;

--check that there aren't a lot of unassigned parcels
select count(*) from parcel where jurisdiction_id is null;

--make a map table to check them out
create table admin_staging.nojuris_parcels as
select * from parcel where jurisdiction_id is null;
