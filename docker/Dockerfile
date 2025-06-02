FROM robinlovelace/geocompr:ubuntu

# System dependencies for building R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    build-essential \
    libblas-dev \
    liblapack-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libfontconfig1-dev \
    r-base-dev \
    r-cran-sf \
    r-cran-raster \
    r-cran-rjava \
    gfortran \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy lockfile and project source
COPY renv.lock ./

# Install renv and restore packages
RUN R -e "install.packages('renv'); renv::restore(lockfile = 'renv.lock', clean = TRUE)"

# Default command
CMD ["R"]
