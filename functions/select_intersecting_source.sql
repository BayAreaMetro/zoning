select a.parcel_id, a.geom, a.tablename, s.matchfield
FROM 
zoning.source_field_name s,
(select *
from pz limit 1) a
WHERE s.tablename = a.tablename;