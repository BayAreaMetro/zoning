ALTER TABLE pz_valid ADD COLUMN id INTEGER;
CREATE SEQUENCE pz_valid_id_seq;
UPDATE pz_valid  SET id = nextval('pz_valid_id_seq');
ALTER TABLE pz_valid ALTER COLUMN id SET DEFAULT nextval('pz_valid_id_seq');
ALTER TABLE pz_valid ALTER COLUMN id SET NOT NULL;
ALTER TABLE pz_valid ADD PRIMARY KEY (id);

UPDATE zoning.source_field_name
SET matchfield = 'zoning'
WHERE juris=27

UPDATE zoning.source_field_name 
SET tablename = 'alamedacountygp2006db'
where tablename like '%alamedagp2%'

UPDATE zoning.source_field_name 
SET matchfield = 'new_zoning'
where tablename = 'elcerritozoning'

UPDATE zoning.source_field_name 
SET matchfield = 'urbsimlu'
where tablename = 'fremontgeneralplan'

UPDATE zoning.source_field_name 
SET matchfield = 'dxf_text'
where tablename = 'orinda_zoning'