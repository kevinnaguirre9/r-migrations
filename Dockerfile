FROM r-base:latest

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  pkg-config \
  libcurl4-openssl-dev \
  zlib1g-dev \
  libssl-dev \
  libsasl2-dev \
  libz-dev \
  libxml2-dev \
  libmariadb-dev

RUN R -e "install.packages(c('RMySQL', 'mongolite', 'tidyr', 'dplyr', 'purrr'), repos = 'http://cran.rstudio.com/', dependencies = TRUE)"

COPY . /usr/local/src/myscripts

WORKDIR /usr/local/src/myscripts