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