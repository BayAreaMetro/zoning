DROP TABLE IF EXISTS parcels_geography_old;
CREATE TABLE parcels_geography_old (
    geom_id bigint,
    jurisdiction integer,
    tpp_id text,
    exp_id text,
    pda_id text,
    juris_name text
);

\COPY parcels_geography_old FROM '2015_10_07_2_parcels_geography.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

CREATE TABLE parcels_geography_new as
    SELECT * from parcels_geography_old;

UPDATE parcels_geography_new o
    SET juris_name = u.name10
    FROM admin_staging.parcels_jurisdictions u
    WHERE o.geom_id = u.geom_id;

\COPY parcels_geography_new to '2016_01_26_parcels_geography.csv' DELIMITER ',' C