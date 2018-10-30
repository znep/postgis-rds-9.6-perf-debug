FROM ubuntu

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
  apt-get -y install wget ca-certificates gnupg2 lsb-release sudo  libjson-c-dev libxml2-dev less proj-bin proj-data nvi

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install  postgresql-9.6 && /etc/init.d/postgresql start

RUN wget  https://download.osgeo.org/postgis/source/postgis-2.3.4.tar.gz && tar xzf postgis-2.3.4.tar.gz

RUN wget http://download.osgeo.org/geos/geos-3.6.2.tar.bz2 && tar xjf geos-3.6.2.tar.bz2 

RUN (cd geos-3.6.2 &&  ./configure && make && make install)

RUN wget http://download.osgeo.org/gdal/2.1.3/gdal-2.1.3.tar.gz && tar xzf gdal-2.1.3.tar.gz
RUN (cd gdal-2.1.3 && ./configure && make && make install)

# bug in postgis causes "\echo" to turn into an escape char followed by echo using dash, so hack around that
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN (apt-get install -y  postgresql-server-dev-9.6 libproj-dev && cd postgis-2.3.4 && ./configure && make && make install)
RUN ldconfig

RUN wget -O - https://znep.com/~marcs/tmp/t19669_8_1.sql.gz | gzip -d > /root/t19669_8_1.sql

RUN /etc/init.d/postgresql start && sleep 2 && \
  echo 'create extension postgis' | sudo -u postgres psql && \
  cat t19669_8_1.sql | sudo -u postgres psql && \
  /etc/init.d/postgresql stop

CMD /etc/init.d/postgresql start ; /bin/bash
