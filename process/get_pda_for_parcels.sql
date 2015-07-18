--SELECT UpdateGeometrySRID('public','parcel','centroid',26910);

CREATE INDEX parcel_centroid_gidx ON public.parcel USING GIST (centroid);

vacuum (analyze) public.parcel;

DROP TABLE IF EXISTS admin.parcel_pda;
CREATE TABLE admin.parcel_pda AS
SELECT pda.pda, p.geom_id, p.ghsh_pnt_srfc, p.ghsh_cntrd FROM
	(select lower(id_1) as pda, geom from admin.pda) AS pda,
	(select geom_id, ghsh_pnt_srfc, ghsh_cntrd, geom from parcel) AS p
WHERE ST_Within(st_centroid(p.geom),pda.geom);
COMMENT ON TABLE zoning.parcel_intersection is 'st_intersects of parcels and admin.pdas';

\COPY admin.parcel_pda TO '/vm_project_dir/zoning/pdas_parcels.csv' DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS admin.parcel_pda_geo;
CREATE TABLE admin.parcel_pda_geo AS
SELECT geom from parcel where geom_id in (select geom_id from admin.parcel_pda);
COMMENT ON TABLE zoning.parcel_intersection is 'geo table of st_intersects of parcels and admin.pdas';
