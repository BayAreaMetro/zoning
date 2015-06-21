CREATE TABLE zoning.missing_zones_for_id_fix AS
SELECT * from 
zoning.codes_string_matching_fix_replacements b,
zoning.code_additions a,
zoning.merged_jurisdictions m
where m.zoning=a.name OR m.zoning=b.name;

