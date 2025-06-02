FROM rstudio/r-base:4.5-jammy

# Install remotes
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gcc \
    r-cran-remotes \
    r-cran-doparallel



# Copy dependencies and install them
COPY req req
RUN Rscript req/exe.R

# Create new working directory
WORKDIR wrp

# copy the folder code and the main.r code
ADD code code
ADD main.r .

ENTRYPOINT ["Rscript", "--vanilla", "main.r"]
