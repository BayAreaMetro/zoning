UPDATE zoning.parcel_withdetails as z
SET 
id = 0000,
juris = 0000,
city = z.city,
tablename = z.tablename,
name = z.name,
min_far = 0,
max_height = 0,
max_far = 0,
min_front_setback = 0,
max_front_setback = 0,
side_setback = 0,
rear_setback = 0,
min_dua = 0,
max_dua = 0,
coverage = 0,
max_du_per_parcel = 0,
min_lot_size = 0,
hs = 0,ht = 0,hm = 0,of = 0,ho = 0,sc = 0,il = 0,iw = 0,ih = 0,rs = 0,rb = 0,mr = 0,mt = 0,me = 0,
geom_id = z.geom_id,
geom = z.geom,
nodev = 0
FROM 
no_dev_source nd
WHERE ST_Within(nd.centroid,z.geom);