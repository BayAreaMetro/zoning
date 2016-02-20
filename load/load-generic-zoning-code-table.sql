DROP TABLE IF EXISTS zoning_staging.codes_dictionary;
CREATE TABLE zoning_staging.codes_dictionary (
	id integer,
	juris integer, 
	city text, 
	name text, 
	max_far numeric(10,3), 
	max_height numeric(20,3),
	max_dua numeric(10,3),
	max_du_per_parcel numeric(40,3),
	HS text,
	HT text, 
	HM text, 
	of text, 
	HO text, 
	SC text, 
	IL text, 
	IW text, 
	IH text, 
	RS text, 
	RB text, 
	MR text, 
	MT text, 
	ME text 
);

\COPY zoning_staging.codes_dictionary FROM 'data/zoning_lookup.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);
