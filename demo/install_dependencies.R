# use this script to install a number of dependencies.

packages = x <- scan("requirements.txt", what="", sep="\n")

packagecheck <- match( packages, utils::installed.packages()[,1] )
packagestoinstall <- packages[ is.na( packagecheck ) ]

if( length( packagestoinstall ) > 0L ) {
  utils::install.packages( packagestoinstall,
                           repos = "http://cran.csiro.au"
  )
} else {
  print( "All requested packages already installed" )
}

for( package in packages ) {
  suppressPackageStartupMessages(
    library( package, character.only = TRUE, quietly = TRUE )
  )
}

# install.packages(setdiff(packages, rownames(installed.packages())))  
# lapply(packages, require, character.only = TRUE)

rm(list = ls.str())
