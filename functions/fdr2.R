# function to read dataset characteristics, code from: https://github.com/EMODnet/EMODnet-Biology-Benthos_greater_North_Sea
fdr2_to_remove<-function(dasid){
  datasetrecords <- datasets(dasid)
  dascitations <- getdascitations(datasetrecords)
  if(nrow(dascitations)==0)dascitations<-tibble(dasid=as.character(dasid),title="",citation="")
  if(nrow(dascitations)==1) if(is.na(dascitations$citation)) dascitations$citation<-""
  daskeywords <- getdaskeywords(datasetrecords)
  if(nrow(daskeywords)==0)daskeywords<-tibble(dasid=as.character(dasid),title="",keyword="")
  if(nrow(daskeywords)==1) if(is.na(daskeywords$keyword))daskeywords$keyword<-""
  dascontacts <- getdascontacts(datasetrecords)
  if(nrow(dascontacts)==0)dascontacts<-tibble(dasid=as.character(dasid),title="",contact="")
  if(nrow(dascontacts)==1) if(is.na(dascontacts$contact))dascontacts$contact<-""
  dastheme <- getdasthemes(datasetrecords)
  if(nrow(dastheme)==0)dastheme<-tibble(dasid=as.character(dasid),title="",theme="")
  if(nrow(dastheme)==1) if(is.na(dastheme$theme))dastheme$theme<-""
  dastheme2 <- aggregate(theme ~ dasid, data = dastheme, paste,
                         collapse = " , ")
  daskeywords2 <- aggregate(keyword ~ dasid, data = daskeywords,
                            paste, collapse = " , ")
  dascontacts2 <- aggregate(contact ~ dasid, data = dascontacts,
                            paste, collapse = " , ")
  output <- dascitations %>% left_join(dascontacts2, by = "dasid") %>%
    left_join(dastheme2, by = "dasid") %>% left_join(daskeywords2,
                                                     by = "dasid")
  return(output)
}




fdr2 <- function(dasid) {
    datasetrecords <- datasets(dasid)

    # Helper function to safely fetch and clean metadata
    safe_fetch <- function(fetch_fn, column, default_title = "") {
        df <- fetch_fn(datasetrecords)

        if (nrow(df) == 0) {
            df <- tibble(dasid = as.character(dasid),
                         title = default_title,
                         !!column := "")
        }

        if (nrow(df) == 1 && is.na(df[[column]])) {
            df[[column]] <- ""
        }

        df
    }

    # Fetch and clean all metadata
    dascitations <- safe_fetch(getdascitations, "citation")
    daskeywords  <- safe_fetch(getdaskeywords, "keyword")
    dascontacts  <- safe_fetch(getdascontacts, "contact")
    dastheme     <- safe_fetch(getdasthemes, "theme")

    # Aggregate fields
    daskeywords2 <- daskeywords %>%
        group_by(dasid) %>%
        summarise(keyword = paste(keyword, collapse = " , "),
                  .groups = "drop")

    dascontacts2 <- dascontacts %>%
        group_by(dasid) %>%
        summarise(contact = paste(contact, collapse = " , "),
                  .groups = "drop")

    dastheme2 <- dastheme %>%
        group_by(dasid) %>%
        summarise(theme = paste(theme, collapse = " , "),
                  .groups = "drop")

    # Join all metadata together
    output <- dascitations %>%
        left_join(dascontacts2, by = "dasid") %>%
        left_join(dastheme2, by = "dasid") %>%
        left_join(daskeywords2, by = "dasid")

    return(output)
}
