CREATE OR REPLACE FUNCTION zoning.select_generic_source(parcelid int)
RETURNS TABLE (city text, source_name text) AS $$
	begin
	RETURN QUERY
		SELECT 
			z.city, z.name as source_name
		FROM 
			zoning.codes_base2012 z
		WHERE
			z.id IN (
				SELECT
					zoning_id
				FROM
					zoning.parcels_auth p 
				WHERE
					p.joinnuma = parcelid
			)
		;
	end;
$$ LANGUAGE plpgsql;