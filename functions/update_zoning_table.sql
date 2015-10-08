CREATE OR REPLACE FUNCTION zoning.update_table(tablename text, zoning_field text)
   RETURNS void AS
$BODY$
DECLARE
		sql_string text := '';
BEGIN
	sql_string := (SELECT '
		CREATE TABLE zoning_staging.update_'|| $1 ||' as
		select zp.geom_id, ut.' || $2 || ', '|| quote_LITERAL($1) ||'as tablename from zoning.parcel zp, parcel p, '
		|| $1 || ' ut where p.geom_id=zp.geom_id AND p.geom && ut.geom AND st_intersects(p.geom,ut.geom)'
	);
 	RAISE NOTICE '%', sql_string;
 	EXECUTE sql_string;
	END;
$BODY$
  LANGUAGE plpgsql VOLATILE;