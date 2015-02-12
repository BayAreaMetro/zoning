CREATE TABLE lgcy_prcls_znng
(prcl_id int, znng_id float, juris varchar);

COPY lgcy_prcls_znng FROM '\legacy\zoning\prcls_znng.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE lgcy_prcls_znng ALTER COLUMN znng_id TYPE int USING znng_id::int;