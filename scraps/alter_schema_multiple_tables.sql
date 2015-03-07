--from http://stackoverflow.com/questions/10218768/change-schema-of-multiple-postgresql-tables-in-one-operation
DO
$$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' -- and other conditions, if needed
    LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(row.tablename) || ' SET SCHEMA zoning_2012_legacy;';
    END LOOP;
END;
$$;