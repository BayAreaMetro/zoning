--this function is based on the functions in this postgis add-ons repository: https://github.com/pedrogit/postgisaddons
--and these plpgsql tutorials: https://wiki.postgresql.org/wiki/Return_more_than_one_row_of_data_from_PL/pgSQL_functions
create or replace function GetOverlaps(_p text,_z text,_z_id text,_z_geom text) returns setof record as
'
declare
r record;
begin
	for r in EXECUTE ''SELECT 
			geom_id,
			''|| _z_id || '',
			sum(ST_Area(geom)) area,
			round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
			ST_Union(geom) geom
			FROM (
				SELECT p.geom_id, 
					z.''|| _z_id || '', 
				 	ST_Area(p.geom) parcelarea, 
				 	ST_Intersection(p.geom, z.geom) geom 
				FROM (select geom_id, geom FROM '' || _p || '') as p, 
					 (select ''|| _z_id || '', '' || _z_geom || 
					 '' as geom FROM '' || _z || '') as z
				WHERE ST_Intersects(z.geom, p.geom)
				) f
				GROUP BY 
					geom_id,
					''|| _z_id || '''' loop
return next r;
end loop;
return;
end
'
language 'plpgsql';

/*
select * from GetOverlaps('parcel','zoning_staging.santarosageneralplan','gp_landuse','wkb_geometry') as codes(
		geom_id bigint, 
  		zoning_id varchar(50),
		area double precision,
		prop double precision,
		geom geometry);
*/
