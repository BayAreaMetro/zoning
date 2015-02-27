CREATE TABLE administrative.places_jason (
id integer,
objectid integer,
name text,
key integer,
county_fip integer,
st_area_sh numeric(12,3),
st_length_ numeric(12,3),
the_geom geometry,
county text
);

COPY administrative.places_jason FROM '/zoning_data/csv_process/geography_city_3_19.txt' WITH (FORMAT csv, DELIMITER E'\t', HEADER TRUE);

select UpdateGeometrySRID('administrative', 'places_jason', 'the_geom', 26910) 

CREATE INDEX places_jason_idx ON administrative.places_jason USING GIST (the_geom);
