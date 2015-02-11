import os
USERNAME = os.environ['LANDUSE_USERNAME']
PASSWORD = os.environ['LANDUSE_PASSWORD']
HOST = os.environ['LANDUSE_HOST']

import pandas as pd
import numpy as np
import psycopg2
import numpy 
psycopg2.extensions.register_adapter(numpy.int64, psycopg2._psycopg.AsIs)

file = "data/prcls2znng.csv"

prcls2znng = pd.read_csv(file)

znng_id_arry = prcls2znng['joinnumA']

try:
    conn=psycopg2.connect("dbname=landuse user=%s password=%s host=%s" % (USERNAME, PASSWORD, HOST))
except:
    print "I am unable to connect to the database."

cur = conn.cursor()
cur.execute("""SELECT joinnuma FROM parcels_mpg""")

prcl_ids = cur.fetchall()

prcl_ids = pd.Series([int(x[0]) for x in prcl_ids])

prcl_has_zoning_id = prcl_ids.isin(znng_id_arry)

parcels_without_zoning_ids = [not x for x in prcl_has_zoning_id]

query_ids= list(prcl_ids[parcels_without_zoning_ids])

#create new table from missing values
prcls_mssng_znng_frm_db = cur.execute("CREATE TABLE nozoning AS SELECT * FROM parcels_mpg WHERE joinnuma = ANY(%s)",[query_ids])

conn.commit()

