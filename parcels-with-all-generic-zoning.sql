CREATE TABLE zoning.industrial_parcels_joinnuma AS
SELECT c.name, c.IL, c.IW, c.IH, p.joinnuma
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
	c.id,
	c.juris, 
	c.city, 
	c.name, 
	c.min_far, 
	c.max_far, 
	c.max_height,
	c.min_front_setback,
	c.max_front_setback,
	c.side_setback,
	c.rear_setback,
	c.min_dua,
	c.max_dua,
	c.coverage,
	c.max_du_per_parcel,
	c.min_lot_size,
	p.geom
	from zoning.auth_geo as p 
	LEFT JOIN zoning.codes_base2012 as c
	ON c.id = p.zoning_id;