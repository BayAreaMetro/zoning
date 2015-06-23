DROP TABLE IF EXISTS no_dev_source;
CREATE TABLE no_dev_source (
	centroid geometry(Point, 2768),
	latitude numeric(24,20),
	longitude numeric(24,20)
);

\COPY no_dev_source FROM 'no_dev1_geo_only.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);
