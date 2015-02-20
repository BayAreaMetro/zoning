CREATE INDEX bayarea_2012_gix ON zoning.bayarea_2012 USING GIST (wkb_geometry);
CREATE INDEX bayarea_2008_gix ON zoning.bayarea_2008 USING GIST (wkb_geometry);
CREATE INDEX nozoning_gix ON zoning.nozoning USING GIST (geom);