--kindly shared by Pierre Racine from the Centre d'étude de la forêt at FOSS4G-NA 2015
SELECT parcel_id, 
       ctype, 
       sum(ST_Area(geom)) area, 
       round(sum(ST_Area(geom))/min(bufferarea) * 1000) / 10 prop, 
       ST_Union(geom) geom
FROM (SELECT p.parcel_id, z.zoning_id, ST_Area(p.geom) parcelarea, ST_Intersection(p.geom, z.geom) geom --does p.id need to be unique or should be joinnuma?
      FROM parcels p, source_zoning z
      WHERE ST_Intersects(p.geom, z.geom)) foo
GROUP BY id, ctype
ORDER BY id, area DESC, ctype;

-- Display
SELECT * 
FROM d_random_buffers_fm_coverarea_1000_mtm7;