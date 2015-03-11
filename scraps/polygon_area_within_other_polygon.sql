--kindly shared by Pierre Racine from the Centre d'étude de la forêt at FOSS4G-NA 2015
CREATE TABLE d_random_buffers_fm_coverarea_1000_mtm7 AS
SELECT id, 
       ctype, 
       sum(ST_Area(geom)) area, 
       round(sum(ST_Area(geom))/min(bufferarea) * 1000) / 10 prop, 
       ST_Union(geom) geom
FROM (SELECT buf.id, ctype, ST_Area(buf.geom) bufferarea, ST_Intersection(buf.geom, c.geom) geom
      FROM d_random_buffers_fm_1000_mtm7 buf, a_forestcover_mtm7 c
      WHERE ST_Intersects(buf.geom, c.geom)) foo
GROUP BY id, ctype
ORDER BY id, area DESC, ctype;

-- Display
SELECT * 
FROM d_random_buffers_fm_coverarea_1000_mtm7;