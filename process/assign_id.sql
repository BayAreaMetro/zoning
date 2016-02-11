ALTER TABLE parcel
    ADD COLUMN zoning_id integer;

ALTER TABLE zoning_staging.codes_dictionary
    ADD COLUMN geoid10_int integer;

ALTER TABLE zoning_staging.codes_dictionary
    ADD COLUMN county boolean;

UPDATE zoning_staging.codes_dictionary
    SET county=true
WHERE city LIKE 'Unincorporated%';

UPDATE zoning_staging.codes_dictionary
    SET county=true
WHERE city LIKE '%County';

UPDATE zoning_staging.codes_dictionary
    SET county=false
WHERE county is null; 

UPDATE zoning_staging.codes_dictionary m
    SET geoid10_int = j.geoid10_int
FROM
   admin_staging.jurisdictions j
WHERE j.county=false AND 
m.county=false AND
j.name10=m.city;

UPDATE zoning_staging.codes_dictionary m
    SET geoid10_int = j.geoid10_int
FROM
   admin_staging.jurisdictions j
WHERE j.county=true 
AND m.county=true AND
j.name10=replace(m.city, 'Unincorporated ', '');

UPDATE zoning_staging.codes_dictionary m
    SET geoid10_int = j.geoid10_int
FROM
   admin_staging.jurisdictions j
WHERE j.county=true 
AND m.county=true AND
j.name10=replace(m.city, ' County', '');

UPDATE parcel p
  SET zoning_id=q.id
FROM
(SELECT id, name, geoid10_int, city FROM zoning_staging.codes_dictionary) q
WHERE p.zoning_name = q.name
AND p.geoid10_int = q.geoid10_int;