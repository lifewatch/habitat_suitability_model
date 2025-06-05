FROM rocker/r-ver:4.2.2

# System dependencies for building R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    build-essential \
    libblas-dev \
    liblapack-dev \
    gfortran \
    libudunits2-dev \
    libsodium-dev \
    libgdal-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    freetype2-demos \
    protobuf-compiler \
    libprotobuf-dev \
    php-xml \
    libjq-dev \
    libmagick++-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy lockfile and project source
COPY renv.lock ./

# Install renv and restore packages
RUN R -e "install.packages('renv'); renv::restore(lockfile = 'renv.lock', clean = TRUE)"
RUN mkdir /wrp
COPY functions/ /wrp/functions
RUN mkdir /wrp/utils
COPY utils/ /wrp/utils

# Default command
CMD ["R"]
