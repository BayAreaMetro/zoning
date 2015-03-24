
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