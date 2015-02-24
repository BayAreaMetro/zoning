#customization of boilerplate from postgis
CREATE EXTENSION
CREATE EXTENSION
1|Devonshire|Pl|02109
TMPDIR="/d/tiger/temp"
UNZIPTOOL=unzip
WGETTOOL="/usr/bin/wget"
export PGPORT=5432
export PGHOST=localhost
export PGUSER=
export PGPASSWORD=
export PGDATABASE=DATABASE

wget ftp://ftp2.census.gov/geo/tiger/TIGER2013/STATE/ --no-parent --relative --recursive --level=1 --accept=zip --mirror --reject=html 
cd gisdata/ftp2.census.gov/geo/tiger/TIGER2013/STATE
rm -f ${TMPDIR}/*.*
psql -U DBUSERNAME -d DATABASE -c "DROP SCHEMA IF EXISTS tiger_staging CASCADE;"
psql -U DBUSERNAME -d DATABASE -c"CREATE SCHEMA tiger_staging;"
for z in tl_*state.zip ; do $UNZIPTOOL -o -d $TMPDIR $z; done
for z in */tl_*state.zip ; do $UNZIPTOOL -o -d $TMPDIR $z; done
cd $TMPDIR;

psql -U DBUSERNAME -d DATABASE -c "CREATE TABLE tiger_data.state_all(CONSTRAINT pk_state_all PRIMARY KEY (statefp),CONSTRAINT uidx_state_all_stusps  UNIQUE (stusps), CONSTRAINT uidx_state_all_gid UNIQUE (gid) ) INHERITS(state); "
shp2pgsql -c -s 4269 -g the_geom   -W "latin1" tl_2013_us_state.dbf tiger_staging.state | psql -U DBUSERNAME -d DATABASE 
psql -U DBUSERNAME -d DATABASE -c "SELECT loader_load_staged_data(lower('state'), lower('state_all')); "
	psql -U DBUSERNAME -d DATABASE -c "CREATE INDEX tiger_data_state_all_the_geom_gist ON tiger_data.state_all USING gist(the_geom);"
	psql -U DBUSERNAME -d DATABASE -c "VACUUM ANALYZE tiger_data.state_all"
cd gisdata
wget ftp://ftp2.census.gov/geo/tiger/TIGER2013/COUNTY/ --no-parent --relative --recursive --level=1 --accept=zip --mirror --reject=html 
cd ftp2.census.gov/geo/tiger/TIGER2013/COUNTY
rm -f ${TMPDIR}/*.*
psql -U DBUSERNAME -d DATABASE -c "DROP SCHEMA IF EXISTS tiger_staging CASCADE;"
psql -U DBUSERNAME -d DATABASE -c "CREATE SCHEMA tiger_staging;"
for z in tl_*county.zip ; do $UNZIPTOOL -o -d $TMPDIR $z; done
for z in */tl_*county.zip ; do $UNZIPTOOL -o -d $TMPDIR $z; done
cd $TMPDIR;

psql -U DBUSERNAME -d DATABASE -c "CREATE TABLE tiger_data.county_all(CONSTRAINT pk_tiger_data_county_all PRIMARY KEY (cntyidfp),CONSTRAINT uidx_tiger_data_county_all_gid UNIQUE (gid)  ) INHERITS(county); " 
shp2pgsql -c -s 4269 -g the_geom -W "latin1" tl_2013_us_county.dbf tiger_staging.county | psql -U DBUSERNAME -d DATABASE
psql -U DBUSERNAME -d DATABASE -c "ALTER TABLE tiger_staging.county RENAME geoid TO cntyidfp;  SELECT loader_load_staged_data(lower('county'), lower('county_all'));"
	psql -U DBUSERNAME -d DATABASE -c "CREATE INDEX tiger_data_county_the_geom_gist ON tiger_data.county_all USING gist(the_geom);"
	psql -U DBUSERNAME -d DATABASE -c "CREATE UNIQUE INDEX uidx_tiger_data_county_all_statefp_countyfp ON tiger_data.county_all USING btree(statefp,countyfp);"
	psql -U DBUSERNAME -d DATABASE -c "CREATE TABLE tiger_data.county_all_lookup ( CONSTRAINT pk_county_all_lookup PRIMARY KEY (st_code, co_code)) INHERITS (county_lookup);"
	psql -U DBUSERNAME -d DATABASE -c "VACUUM ANALYZE tiger_data.county_all;"
	psql -U DBUSERNAME -d DATABASE -c "INSERT INTO tiger_data.county_all_lookup(st_code, state, co_code, name) SELECT CAST(s.statefp as integer), s.abbrev, CAST(c.countyfp as integer), c.name FROM tiger_data.county_all As c INNER JOIN state_lookup As s ON s.statefp = c.statefp;"
	psql -U DBUSERNAME -d DATABASE -c "VACUUM ANALYZE tiger_data.county_all_lookup;" 
