CREATE TABLE zoning.source_name
(
  parcel_id bigint,
  zonename text,
  juris integer,
)

CREATE TABLE zoning.lookup_new
(
 ogc_fid integer, 
 tablename text, 
 geom geometry, 
 zoning text, 
 juris integer
)

drop table zoning.no_source_name;
create table zoning.no_source_name as SELECT ogc_fid,tablename,parcel_id,id as pzvalid_id FROM pz_valid limit 0;


INSERT INTO zoning.source_name
select * 
from 
test_zone((select parcel_id from pz_valid));

select zt.parcel_id, zc.id 
from 
zoning.codes_base2012 zc,
zoning.source_name zt
WHERE zt.zonename=zc.name 
AND zt.juris=zc.juris