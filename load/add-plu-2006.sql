--on a 100GB VM this takes about 40 minutes
create INDEX plu06_may2015estimate_gidx ON zoning.plu06_may2015estimate using GIST (geom);
create INDEX plu06_may2015estimate_idx ON zoning.plu06_may2015estimate using hash (objectid);
VACUUM (ANALYZE) zoning.plu06_may2015estimate;

#seems not necessary w/shp2pgsql import: alter table zoning.plu06_may2015estimate rename column of_ to of;

#seems not necessary w/shp2pgsql import: UPDATE zoning.plu06_may2015estimate SET IH = case when IH = '1' then '1' else '0' end;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;

ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN juris TYPE INTEGER USING HS::INTEGER;

ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning.plu06_may2015estimate ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;

