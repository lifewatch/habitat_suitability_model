import copernicusmarine as cm

cm.login
username = ""
password = ""

#For temperature want to use GLOBAL_MULTIYEAR_PHY_001_030
#For Net primary production want to use: GLOBAL_MULTIYEAR_BGC_001_033

cm.subset(
  dataset_id="cmems_mod_glo_phy_my_0.083deg_P1M-m",
  dataset_version="202311",
  variables=["so", "thetao"],
  minimum_longitude=-12.01498103062979,
  maximum_longitude=13.645282778488214,
  minimum_latitude=47.183697679290205,
  maximum_latitude=61.77604047194526,
  start_datetime="1999-01-01T00:00:00",
  end_datetime="2021-06-01T00:00:00",
  minimum_depth=0.49402499198913574,
  maximum_depth=0.49402499198913574,
)

# cm.subset(
#   dataset_id="cmems_mod_glo_bgc_my_0.083deg-lmtl_PT1D-i",
#   dataset_version="202211",
#   variables=["npp"],
#   minimum_longitude=-12.01498103062979,
#   maximum_longitude=13.645282778488214,
#   minimum_latitude=47.183697679290205,
#   maximum_latitude=61.77604047194526,
#   start_datetime="1999-01-01T00:00:00",
#   end_datetime="2022-12-31T00:00:00",
# )
