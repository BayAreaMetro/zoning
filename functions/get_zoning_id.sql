CREATE OR REPLACE FUNCTION zoning.get_id(name text,juris int)
   RETURNS int AS
$$
  SELECT id 
  from zoning.codes_dictionary 
  WHERE name = $1 
  AND juris = $2;
$$
  LANGUAGE sql;