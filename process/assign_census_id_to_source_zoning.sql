ALTER TABLE zoning_staging.shapefile_metadata
    ADD COLUMN geoid10_int integer;

UPDATE zoning_staging.shapefile_metadata m
    SET geoid10_int = j.geoid10_int
FROM
   admin_staging.jurisdictions j
WHERE j.county=false AND 
m.county=false AND
j.name10=m.common_name;

UPDATE zoning_staging.shapefile_metadata m
    SET geoid10_int = j.geoid10_int
FROM
   admin_staging.jurisdictions j
WHERE j.county=true 
AND m.county=true AND
j.name10=m.common_name;

\COPY zoning_staging.shapefile_metadata to 'data/zoning_source_metadata.csv' DELIMITER ',' CSV HEADER;
