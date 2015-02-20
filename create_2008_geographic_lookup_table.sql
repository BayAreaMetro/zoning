CREATE TABLE zoning.bayarea_2008
(
  ogc_fid integer,
  table_name character varying,
  wkb_geometry geometry(MultiPolygon,26910)
);
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_alameda', ST_Force2D(wkb_geometry) from lgcy_znng_alameda;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_contracosta', ST_Force2D(wkb_geometry) from lgcy_znng_contracosta;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_marin', ST_Force2D(wkb_geometry) from lgcy_znng_marin;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_pda_final', ST_Force2D(wkb_geometry) from lgcy_znng_pda_final;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_sanfrancisco', ST_Force2D(wkb_geometry) from lgcy_znng_sanfrancisco;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_sanmateo', ST_Force2D(wkb_geometry) from lgcy_znng_sanmateo;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_santaclara', ST_Force2D(wkb_geometry) from lgcy_znng_santaclara;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_solano', ST_Force2D(wkb_geometry) from lgcy_znng_solano;
insert into zoning.bayarea_2008  
select ogc_fid, 'lgcy_znng_sonoma', ST_Force2D(wkb_geometry) from lgcy_znng_sonoma;