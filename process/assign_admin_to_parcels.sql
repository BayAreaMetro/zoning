--IN THE FUTURE, THESE SHOULD JUST BE PART OF THE parcel table?
DROP TABLE IF EXISTS admin.parcel_counties;
CREATE TABLE admin.parcel_counties AS
SELECT county.name10 as name1, 
county.namelsad10 as name2, 
county.geoid10 countygeoid, 
p.geom_id
FROM
admin.county10_ca county,
parcel p
WHERE ST_Intersects(county.geom, p.geom);
COMMENT ON TABLE admin.parcel is 'parcels st_intersect with census 2010 county boundaries';

DROP INDEX IF EXISTS admin_parcels_counties_geomid_idx;
CREATE INDEX admin_parcels_counties_geomid_idx ON admin.parcel_counties using hash (geom_id);

DROP INDEX IF EXISTS admin_parcel_counties_name_idx;
CREATE INDEX admin_parcel_counties_name_idx ON admin.parcel_counties using hash (name1);

VACUUM (ANALYZE) admin.parcel_counties;

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
COMMENT ON TABLE admin.parcel is 'parcels st_intersect with census 2010 city boundaries';

DROP INDEX IF EXISTS admin_parcels_cities_geomid_idx;
CREATE INDEX admin_parcels_cities_geomid_idx ON admin.parcel_cities using hash (geom_id);

DROP INDEX IF EXISTS admin_parcel_cities_name_idx;
CREATE INDEX admin_parcel_cities_name_idx ON admin.parcel_cities using hash (name1);

VACUUM (ANALYZE) admin.parcel_cities;
