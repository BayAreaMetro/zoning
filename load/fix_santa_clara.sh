DBUSERNAME=vagrant
DBPASSWORD=vagrant
DBHOST=localhost
DBPORT=5432
DBNAME=vagrant 

#FIX for Santa Clara
ogr2ogr -skipfailures -f "PostgreSQL" \
PG:"host=${DBHOST} port=${DBPORT} dbname=${DBNAME} user=${DBUSERNAME} password=${DBPASSWORD}" \
-nlt PROMOTE_TO_MULTI -lco SCHEMA=zoning_staging -lco OVERWRITE=YES City_Santa_Clara_GP_LU_02.shp

psql <<EOF
update zoning.source_field_name 
set tablename='City_Santa_Clara_GP_LU_02' 
where juris=27;

update zoning.source_field_name 
set matchfield='GP_DESIGNA' 
where juris=27;

CREATE INDEX city_santa_clara_gidx ON zoning_staging.City_Santa_Clara_GP_LU_02 using GIST (wkb_geometry);

VACUUM (ANALYZE) zoning_staging.City_Santa_Clara_GP_LU_02;

SELECT c.id as zoning_id, scp.geom_id
FROM
(select geom_id, geom from 
parcel where
geom_id in 
(select geom_id from
zoning.parcel_cities_counties
where cityname1 = 'Santa Clara') ) scp,
zoning_staging.City_Santa_Clara_GP_LU_02 z,
zoning.codes_dictionary c
WHERE 
ST_INTERSECTS(z.wkb_geometry,scp.geom) AND
c.name=z.GP_DESIGNA ;
EOF
