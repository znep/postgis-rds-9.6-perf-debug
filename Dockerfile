FROM ubuntu

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
  apt-get -y install wget ca-certificates gnupg2 lsb-release sudo  libjson-c-dev libxml2-dev less proj-bin proj-data nvi

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install  postgresql-9.6 && /etc/init.d/postgresql start

RUN wget --progress=dot:giga -O - https://znep.com/~marcs/tmp/t19669_8_1.sql.gz | gzip -d > /root/t19669_8_1.sql


ENV GEOS_VERSION=3.5.1
RUN wget --progress=dot:giga http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 && tar xjf geos-$GEOS_VERSION.tar.bz2 

RUN (cd geos-$GEOS_VERSION &&  ./configure && make -j 16 && make install)

RUN wget --progress=dot:giga http://download.osgeo.org/gdal/2.1.3/gdal-2.1.3.tar.gz && tar xzf gdal-2.1.3.tar.gz
RUN (cd gdal-2.1.3 && ./configure && make -j 16 && make install)

# bug in postgis causes "\echo" to turn into an escape char followed by echo using dash, so hack around that
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get install -y git autoconf libtool postgresql-server-dev-9.6 libproj-dev
#ENV POSTGIS_VERSION=2.4.0
#RUN wget --progress=dot:giga  https://download.osgeo.org/postgis/source/postgis-$POSTGIS_VERSION.tar.gz && tar xzf postgis-$POSTGIS_VERSION.tar.gz
RUN git clone https://github.com/postgis/postgis.git
ADD attributes postgis/.git/info/

RUN (cd postgis && git checkout 6c84af035e6b63f13725b669e0e871899fb072b6)

#RUN (cd postgis-$POSTGIS_VERSION && ./configure && make -j 16 && make install)
RUN (cd postgis && ./autogen.sh && ./configure && make -j 16 && make install)
RUN ldconfig

RUN /etc/init.d/postgresql start && sleep 10 && \
  cat /usr/share/postgresql/9.6/contrib/postgis-2.3/postgis.sql | sudo -u postgres psql && \
  cat t19669_8_1.sql | sudo -u postgres psql && \
  /etc/init.d/postgresql stop

CMD /etc/init.d/postgresql start ; /bin/bash
