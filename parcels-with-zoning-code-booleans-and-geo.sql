CREATE TABLE zoning.industrial_parcels AS
SELECT c.IL, c.IW, c.IH, p.geom
	from zoning.auth_geo as p 
	LEFT JOIN zoning.codes_base2012 as c
	ON c.id = p.zoning_id
	WHERE c.IL=TRUE OR c.IW=TRUE OR c.IH=TRUE;

CREATE TABLE zoning.parcels_generic_types AS
SELECT c.HS,
	c.HT, 
	c.HM, 
	c.of, 
	c.HO, 
	c.SC, 
	c.IL, 
	c.IW, 
	c.IH, 
	c.RS, 
	c.RB, 
	c.MR, 
	c.MT, 
	c.ME,
	p.geom
	from zoning.auth_geo as p 
	LEFT JOIN zoning.codes_base2012 as c
	ON c.id = p.zoning_id;