ALTER TABLE pz_valid ADD COLUMN id INTEGER;
CREATE SEQUENCE pz_valid_id_seq;
UPDATE pz_valid  SET id = nextval('pz_valid_id_seq');
ALTER TABLE pz_valid ALTER COLUMN id SET DEFAULT nextval('pz_valid_id_seq');
ALTER TABLE pz_valid ALTER COLUMN id SET NOT NULL;
ALTER TABLE pz_valid ADD PRIMARY KEY (id);