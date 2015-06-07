--IN THE FUTURE, THESE SHOULD JUST BE PART OF THE parcel table?
DROP TABLE IF EXISTS admin.parcel_counties;
CREATE TABLE zoning.parcel_counties AS
SELECT county.name10 as countyname1, 
county.namelsad10 as countyname2, 
county.geoid10 countygeoid, 
p.geom_id
FROM
admin.county10_ca county,
parcel p
WHERE ST_Intersects(county.geom, p.geom);
COMMENT ON TABLE zoning.parcel is 'parcels st_intersect with census 2010 county boundaries';

DROP TABLE IF EXISTS admin.parcel_cities;
CREATE TABLE admin.parcel_cities AS
SELECT city.name10 as cityname1, 
city.namelsad10 as cityname2, 
city.geoid10 citygeoid, 
p.geom_id, 
p.geom
FROM 
admin.city10_ba city,
zoning.parcel_counties p 
WHERE ST_Intersects(city.geom, p.geom);

DROP INDEX IF EXISTS zoning_parcel_cities_counties_geomid_idx;
CREATE INDEX zoning_parcel_cities_counties_geomid_idx ON zoning.parcel_cities_counties using hash (geom_id);
DROP INDEX IF EXISTS zoning_codes_dictionary_idx;
CREATE INDEX zoning_parcel_cities_counties_cityname_idx ON zoning.parcel_cities_counties using hash (cityname1);
VACUUM (ANALYZE) zoning.parcel_cities_counties;
COMMENT ON TABLE zoning.parcel is 'parcels st_intersect with census 2010 city boundaries';

