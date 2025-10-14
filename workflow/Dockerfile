FROM rocker/r-ver:4.2.2

# docker build -f workflow/Dockerfile -t marcobolo-hsm:1.0.0 .

LABEL maintainer="josel.fernandez@lifewatch.eu" \
      description="Docker image for Marcobolo's Habitat Suitability Model Workflow" \
      version="1.0"

ENV RENV_VERSION=1.0.3 \
    RENV_PATHS_ROOT=/opt/renv

RUN apt update && apt install -y \
        build-essential \
        gfortran \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libfontconfig1-dev \
        libprotobuf-dev \
        libgdal-dev \
        libgeos-dev \
        libgit2-dev \
        libproj-dev \
        libudunits2-dev \
        libpng-dev \
        libjpeg-dev \
        libtiff-dev \
        libwebp-dev \
        libbz2-dev \
        libzstd-dev \
        liblzma-dev \
        libssh2-1-dev \
        libglpk-dev \
        libglu1-mesa-dev \
        libxt-dev \
        libfribidi-dev \
        libharfbuzz-dev \
        libicu-dev \
        libpq-dev \
        libsodium-dev \
        libsqlite3-dev \
        libgsl-dev \
        libnetcdf-dev \
        unixodbc-dev \
        default-jdk \
        cmake \
        pkg-config \
        git \
        protobuf-compiler \
        libjq-dev \
        libmagick++-dev \
        curl \
        ca-certificates \
        software-properties-common \
        pandoc && \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY renv.lock /usr/src/app/
COPY workflow/DESCRIPTION /usr/src/app/
COPY workflow/workflow_setup.R /usr/src/app/
COPY workflow/load_common_packages.R /usr/src/app/
COPY workflow/execute.R /usr/src/app/
COPY ./functions functions/
COPY ./code code/

RUN Rscript workflow_setup.R

# Optional: If using DESCRIPTION (like an R package), install dependencies
#RUN if [ -f "DESCRIPTION" ]; then \
#        Rscript -e "devtools::install_deps(dependencies = TRUE)"; \
#    fi

ENTRYPOINT ["Rscript", "execute.R"]
