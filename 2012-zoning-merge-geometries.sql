CREATE TABLE public.zoning.bayarea_2012
(
  ogc_fid integer,
  table_name character varying,
  wkb_geometry geometry(MultiPolygon,26910)
);
insert into zoning.bayarea_2012  
select ogc_fid, 'albanyzoningdesignations', ST_Force2D(wkb_geometry) from albanyzoningdesignations;
insert into zoning.bayarea_2012  
select ogc_fid, 'antiochgeneralplan', ST_Force2D(wkb_geometry) from antiochgeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'athertongp2006db', ST_Force2D(wkb_geometry) from athertongp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'belmontgp2006db', ST_Force2D(wkb_geometry) from belmontgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'belvedere_general_plan', ST_Force2D(wkb_geometry) from belvedere_general_plan;
insert into zoning.bayarea_2012  
select ogc_fid, 'beniciagp2006db', ST_Force2D(wkb_geometry) from beniciagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'berkeleyzoning', ST_Force2D(wkb_geometry) from berkeleyzoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'brentwood_zoning', ST_Force2D(wkb_geometry) from brentwood_zoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'brisbanegp2006db', ST_Force2D(wkb_geometry) from brisbanegp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'burlingamegp2006db', ST_Force2D(wkb_geometry) from burlingamegp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'calistogagp2006db', ST_Force2D(wkb_geometry) from calistogagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'campbellgp2006db', ST_Force2D(wkb_geometry) from campbellgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'claytongp2006db', ST_Force2D(wkb_geometry) from claytongp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'colmagp2006db', ST_Force2D(wkb_geometry) from colmagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'concordparcels_gp120607_clip', ST_Force2D(wkb_geometry) from concordparcels_gp120607_clip;
insert into zoning.bayarea_2012  
select ogc_fid, 'corte_madera_general_plan', ST_Force2D(wkb_geometry) from corte_madera_general_plan;
insert into zoning.bayarea_2012  
select ogc_fid, 'dalycitygp2006db', ST_Force2D(wkb_geometry) from dalycitygp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'danvillegp2006db', ST_Force2D(wkb_geometry) from danvillegp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'dixongp2006db', ST_Force2D(wkb_geometry) from dixongp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'dublingeneralplan', ST_Force2D(wkb_geometry) from dublingeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'eastpaloaltogp2006db', ST_Force2D(wkb_geometry) from eastpaloaltogp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'elcerritozoning', ST_Force2D(wkb_geometry) from elcerritozoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'emeryvillegpparcels', ST_Force2D(wkb_geometry) from emeryvillegpparcels;
insert into zoning.bayarea_2012  
select ogc_fid, 'fairfax_general_plan', ST_Force2D(wkb_geometry) from fairfax_general_plan;
insert into zoning.bayarea_2012  
select ogc_fid, 'fremontgeneralplan', ST_Force2D(wkb_geometry) from fremontgeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'gilroygpparcels', ST_Force2D(wkb_geometry) from gilroygpparcels;
insert into zoning.bayarea_2012  
select ogc_fid, 'hayward_gp_landuse', ST_Force2D(wkb_geometry) from hayward_gp_landuse;
insert into zoning.bayarea_2012  
select ogc_fid, 'herculesgp2006db', ST_Force2D(wkb_geometry) from herculesgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'lafayettegp2006db', ST_Force2D(wkb_geometry) from lafayettegp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'livermoregeneralplan', ST_Force2D(wkb_geometry) from livermoregeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'zoning.bayarea_2012', ST_Force2D(wkb_geometry) from zoning.bayarea_2012;
insert into zoning.bayarea_2012  
select ogc_fid, 'losaltosgp2006db', ST_Force2D(wkb_geometry) from losaltosgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'losaltoshillsgp2006db', ST_Force2D(wkb_geometry) from losaltoshillsgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'losgatosgeneralplan', ST_Force2D(wkb_geometry) from losgatosgeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'millbraegeneralplan', ST_Force2D(wkb_geometry) from millbraegeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'moragagp2006db', ST_Force2D(wkb_geometry) from moragagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'morganhillgp2006db', ST_Force2D(wkb_geometry) from morganhillgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'napacozoning', ST_Force2D(wkb_geometry) from napacozoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'napazoning', ST_Force2D(wkb_geometry) from napazoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'newarkgp2006db', ST_Force2D(wkb_geometry) from newarkgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'novatogp2006db', ST_Force2D(wkb_geometry) from novatogp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'oakland_generalplan_2005', ST_Force2D(wkb_geometry) from oakland_generalplan_2005;
insert into zoning.bayarea_2012  
select ogc_fid, 'oakleygp2006db', ST_Force2D(wkb_geometry) from oakleygp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'pittsburggp2006db', ST_Force2D(wkb_geometry) from pittsburggp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'pleasanthillgp2006db', ST_Force2D(wkb_geometry) from pleasanthillgp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'pleasantongeneralplan', ST_Force2D(wkb_geometry) from pleasantongeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'riovistagp2006db', ST_Force2D(wkb_geometry) from riovistagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'rohnertpark_gp_2010', ST_Force2D(wkb_geometry) from rohnertpark_gp_2010;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanbrunogeneralplan', ST_Force2D(wkb_geometry) from sanbrunogeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanfranciscozoning', ST_Force2D(wkb_geometry) from sanfranciscozoning;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanjosegeneralplan2040', ST_Force2D(wkb_geometry) from sanjosegeneralplan2040;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanleandrogp2006db', ST_Force2D(wkb_geometry) from sanleandrogp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanpabloproposed_gplu_112410', ST_Force2D(wkb_geometry) from sanpabloproposed_gplu_112410;
insert into zoning.bayarea_2012  
select ogc_fid, 'sanrafaelgeneralplan', ST_Force2D(wkb_geometry) from sanrafaelgeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'santaclaracity_zoningfeb05', ST_Force2D(wkb_geometry) from santaclaracity_zoningfeb05;
insert into zoning.bayarea_2012  
select ogc_fid, 'santarosageneralplan', ST_Force2D(wkb_geometry) from santarosageneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'solcogeneral_plan_unincorporated', ST_Force2D(wkb_geometry) from solcogeneral_plan_unincorporated;
insert into zoning.bayarea_2012  
select ogc_fid, 'sthelenagp2006db', ST_Force2D(wkb_geometry) from sthelenagp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'sunnyvalegeneralplan', ST_Force2D(wkb_geometry) from sunnyvalegeneralplan;
insert into zoning.bayarea_2012  
select ogc_fid, 'tmptable', ST_Force2D(wkb_geometry) from tmptable;
insert into zoning.bayarea_2012  
select ogc_fid, 'unioncitygp2006db', ST_Force2D(wkb_geometry) from unioncitygp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'vallejogp2006db', ST_Force2D(wkb_geometry) from vallejogp2006db;
insert into zoning.bayarea_2012  
select ogc_fid, 'walnutcreekgenplan', ST_Force2D(wkb_geometry) from walnutcreekgenplan;
--
ALTER TABLE zoning.bayarea_2012 ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_bayarea_2012_id_seq;
UPDATE zoning.bayarea_2012  SET id = nextval('zoning_bayarea_2012_id_seq');
ALTER TABLE zoning.bayarea_2012 ALTER COLUMN id SET DEFAULT nextval('zoning_bayarea_2012_id_seq');
ALTER TABLE zoning.bayarea_2012 ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.bayarea_2012 ADD PRIMARY KEY (id);
--
CREATE INDEX bayarea_2012_gix ON zoning.bayarea_2012 USING GIST (wkb_geometry);