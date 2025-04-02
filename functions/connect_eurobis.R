# Make a connection with the data_lake
connect_eurobis <- function(){data_lake <- arrow::S3FileSystem$create(
  anonymous = T,
  scheme = "https",
  endpoint_override = "s3.waw3-1.cloudferro.com"
)

s3_path = "emodnet/emodnet_biology/12639/eurobis_gslayer_obisenv_19022025.parquet"
eurobis <- arrow::open_dataset(
  s3_path,
  filesystem = data_lake,
  format = "parquet"
)
return(eurobis)
}