DROP TABLE IF EXISTS zoning.codes_string_matching_fixes;
CREATE TABLE zoning.codes_string_matching_fixes (
	tablename text,
	old_name text,
	juris integer,
	missing_id integer,
	correct_name text
);

\COPY zoning.codes_string_matching_fixes FROM 'zoning_codes_fix_string_errors.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

CREATE TABLE zoning.codes_string_matching_fix_replacements as 
SELECT c.id,
c.juris, 
c.city, 
nc.correct_name, 
c.min_far, 
c.max_far, 
c.max_height,
c.min_front_setback,
c.max_front_setback,
c.side_setback,
c.rear_setback,
c.min_dua,
c.max_dua,
c.coverage,
c.max_du_per_parcel,
c.min_lot_size,
c.HS,
c.HT, 
c.HM, 
c.of, 
c.HO, 
c.SC, 
c.IL, 
c.IW, 
c.IH, 
c.RS, 
c.RB, 
c.MR, 
c.MT, 
c.ME
from 
zoning.codes_string_matching_fixes nc,
zoning.codes_dictionary c
where c.name = nc.old_name;

select count(*) from zoning.codes_string_matching_fix_replacements;

DELETE FROM zoning.codes_dictionary
WHERE id in (select id from zoning.codes_string_matching_fix_replacements);

INSERT INTO zoning.codes_dictionary
SELECT * from zoning.codes_string_matching_fix_replacements;

