# Make a connection with the data_lake
connect_eurobis <- function(){data_lake <- arrow::S3FileSystem$create(
  anonymous = T,
  scheme = "https",
  endpoint_override = "s3.waw3-1.cloudferro.com"
)

#Get out the s3 path from the STAC catalogue instead of hardcoding
stac_endpoint_url <- 'https://catalog.dive.edito.eu/'
stac_obj <- rstac::stac(stac_endpoint_url)

emodnet_occurrence <- stac_obj%>%
  collections("emodnet-occurrence_data")%>%
  items()%>%
  get_request()

#gives us the url of the dataset, we need the .parquet file
urls <- rstac::assets_url(emodnet_occurrence)
emodnet_url <- urls[grepl("^https://s3\\.waw3-1\\.cloudferro\\.com/.+\\.parquet$", urls)][1]
s3_path <- stringr::str_split_i(emodnet_url, "s3.waw3-1.cloudferro.com/",2)

eurobis <- arrow::open_dataset(
  s3_path,
  filesystem = data_lake,
  format = "parquet"
)
return(eurobis)
}