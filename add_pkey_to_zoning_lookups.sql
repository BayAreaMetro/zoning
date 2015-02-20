ALTER TABLE zoning.bayarea_2008 ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_bayarea_2008_id_seq;
UPDATE zoning.bayarea_2008  SET id = nextval('zoning_bayarea_2008_id_seq');
ALTER TABLE zoning.bayarea_2008 ALTER COLUMN id SET DEFAULT nextval('zoning_bayarea_2008_id_seq');
ALTER TABLE zoning.bayarea_2008 ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.bayarea_2008 ADD PRIMARY KEY (id);

ALTER TABLE zoning.bayarea_2012 ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_bayarea_2012_id_seq;
UPDATE zoning.bayarea_2012  SET id = nextval('zoning_bayarea_2012_id_seq');
ALTER TABLE zoning.bayarea_2012 ALTER COLUMN id SET DEFAULT nextval('zoning_bayarea_2012_id_seq');
ALTER TABLE zoning.bayarea_2012 ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.bayarea_2012 ADD PRIMARY KEY (id);