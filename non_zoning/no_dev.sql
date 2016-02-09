DROP TABLE IF EXISTS no_dev_source;
CREATE TABLE no_dev_source (
	centroid geometry(Point, 2768),
	latitude numeric(24,20),
	longitude numeric(24,20)
);

\COPY no_dev_source FROM 'no_dev1_geo_only.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE no_dev_source 
   ALTER COLUMN centroid 
   TYPE Geometry(Point, 26910) 
   USING ST_Transform(centroid, 26910);

CREATE INDEX no_dev_source_gidx ON no_dev_source using GIST (centroid);
vacuum (analyze) no_dev_source;
