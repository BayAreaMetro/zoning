import pandas as pd
import orca
import sys
sys.path.append(".")
import datasources

@orca.table('zcsv', cache=True)
def zcsv():
    df = pd.read_csv("zoning_parcels.csv"),
                     index_col="geom_id")
    return df

@orca.table(cache=True)
def zoning_lookup():
    df = pd.read_csv("zoning_lookup.csv"))
    # this part is a bit strange - we do string matching on the names of zoning
    # in order ot link parcels and zoning and some of the strings have small
    # differences, so we copy the row and have different strings for the same
    # lookup row.  for now we drop duplicates of the id field in order to run
    # in urbansim (all the attributes of rows that share an id are the same -
    # only the name is different)
    df = df.drop_duplicates(subset='id').set_index('id')
    return df

@orca.table('zoning_table_city_lookup', cache=True)
def zoning_table_city_lookup():
    df = pd.read_csv("zoning_table_city_lookup.csv"),
                     index_col="juris")
    return df

zl = orca.get_table("zoning_lookup")
z = orca.get_table("zcsv")

zdf = z.to_frame()

zdf.to_csv('zoning_lookup_pre_python_check.csv')

null_df = zdf.loc[zdf.zoning_id.isnull(),:]
print "there are " + str(len(null_df.index)) + " empty zoning ids"
print "number of parcels with null values by city:"
print null_df.tablename.value_counts()

print "number of parcels with null values by source zoning code by city:"
for ix, val in null_df.tablename.value_counts().iteritems():
    if val>5:
        print ix
        print null_df[null_df.tablename==ix].zoning.value_counts()

zl_df = zl.to_frame()

zlcn = orca.get_table("zoning_table_city_lookup")
zlcndf = zlcn.to_frame()
zl_df['zoning_lookup_table_id'] = zl_df.index
zldf_tbl_nm = pd.merge(zl_df,zlcndf,how='left',left_on='city',right_on='city_name')
zl_df = zldf_tbl_nm

null_df['geom_id'] = null_df.index
mdf = pd.merge(null_df,zl_df,how='inner', right_on=['name','tablename'], left_on=['zoning','tablename'])
mdf = mdf.set_index(mdf.geom_id)

print "replaced " + str(len(mdf.index)) + " empty zoning ids"
zdf.loc[mdf.index,'zoning_id'] = mdf['zoning_lookup_table_id']

null_df = zdf.loc[zdf.zoning_id.isnull(),:]
print "there are " + str(len(null_df.index)) + " empty zoning ids"

print "number of parcels with null values by city:"
print null_df.tablename.value_counts()

zdf.to_csv('zoning_parcels.csv')