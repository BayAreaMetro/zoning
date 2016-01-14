RAISE NOTICE 'These are the zoning codes for which we do not have generic definition:';
select distinct(zoning), tablename from zoning.parcel where geom_id not in (select geom_id from zoning.parcel zp, zoning.codes_dictionary zc
where zc.name=zp.zoning AND zp.juris=zc.juris) AND tablename != 'plu06' ORDER BY tablename;