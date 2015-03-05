SELECT  joinnuma, zoning.select_generic_source(joinnuma), select_source_att(j.geom) FROM (SELECT joinnuma, geom
FROM zoning.auth_geo
ORDER BY random()
LIMIT 400) j