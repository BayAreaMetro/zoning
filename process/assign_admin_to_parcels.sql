--IN THE FUTURE, THESE SHOULD JUST BE PART OF THE parcel table?
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

DROP INDEX IF EXISTS admin_staging_parcels_on_jurisdiction_lines_geom_id_idx;
CREATE INDEX admin_staging_parcels_on_jurisdiction_lines_geom_id_idx ON admin_staging.parcels_on_jurisdiction_lines using hash (geom_id);

VACUUM (ANALYZE) admin_staging.parcels_on_jurisdiction_lines;

ALTER TABLE parcel
    ADD COLUMN jurisdiction_id integer;

ALTER TABLE parcel
    ADD COLUMN point_on_surface geometry(POINT,26910);

UPDATE parcel
    SET point_on_surface = ST_PointOnSurface(geom);

DROP INDEX IF EXISTS parcel_point_on_surface_gidx;
    CREATE INDEX parcel_point_on_surface_gidx ON parcel using gist (point_on_surface);

vacuum (analyze) parcel;

CREATE VIEW admin_staging.parcels_not_on_jurisdiction_lines as
    SELECT geom_id FROM parcel
        WHERE geom_id not in
        (select geom_id from admin_staging.parcels_on_jurisdiction_lines);

ALTER TABLE parcel
    ADD COLUMN jurisdiction_id integer;


ALTER TABLE administrative_areas.jurisdictions
    ADD COLUMN county_id integer;

UPDATE administrative_areas.jurisdictions
    SET county_id = CAST (right(geoid10,3) AS INTEGER);

DROP INDEX IF EXISTS jurisdictions_county_id_idx;
    CREATE INDEX jurisdictions_county_id_idx ON administrative_areas.jurisdictions using hash (county_id);

vacuum (analyze) administrative_areas.jurisdictions;

DROP INDEX IF EXISTS parcel_county_id_idx;
    CREATE INDEX parcel_county_id_idx ON parcel using hash (county_id);

vacuum (analyze) parcel;

UPDATE parcel
    SET jurisdiction_id = CAST (juris.geoid10 AS INTEGER)
    FROM parcel p,
    admin_staging.parcels_not_on_jurisdiction_lines p2,
    administrative_areas.jurisdictions juris
    WHERE p.geom_id = p2.geom_id AND
        juris.county_id = p.county_id;

UPDATE parcel
    SET jurisdiction_id = juris.id
    FROM parcel p,
    (select * from administrative_areas.jurisdictions where county=false) juris,
    admin_staging.parcels_not_on_jurisdiction_lines p2
    WHERE 1=1 AND
        p.geom_id = p2.geom_id AND
        juris.geom && p.point_on_surface AND
        ST_Within(p.point_on_surface, juris.geom);

DROP INDEX IF EXISTS admin_staging_jurisdictions_lines;
    CREATE INDEX admin_staging_jurisdictions_lines ON administrative_areas.jurisdictions using gist (boundary_lines);
/*
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



SELECT p.geom_id from
parcel p,
admin_staging_jurisdictions_lines jurisdictions_lines
where p.geom && jurisdictions_lines.geom AND
ST_Intersects(p.geom, jurisdictions_lines.geom)
DROP INDEX IF EXISTS admin_parcel_counties_name_idx;
CREATE INDEX admin_parcel_counties_name_idx ON admin.parcel_counties using hash (name1);



DROP TABLE IF EXISTS admin.parcel_cities;
CREATE TABLE admin.parcel_cities AS
SELECT city.name10 as name1, 
city.namelsad10 as name2, 
city.geoid10 citygeoid, 
p.geom_id, 
p.geom
FROM 
admin.city10_ba city,
parcel p 
WHERE ST_Intersects(city.geom, p.geom);
COMMENT ON TABLE admin.parcel_cities is 'parcels st_intersect with census 2010 city boundaries';




DROP INDEX IF EXISTS admin_parcel_cities_name_idx;
CREATE INDEX admin_parcel_cities_name_idx ON admin.parcel_cities using hash (name1);



VACUUM (ANALYZE) admin.parcel_cities;
*/