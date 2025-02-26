FROM ubuntu:jammy AS builder
RUN apt update && apt install tzdata -y
ENV TZ="Europe/Brussels"
RUN apt-get update && apt-get install -y build-essential gcc g++ automake git-core autoconf make patch libmysql++-dev mysql-server libtool libssl-dev grep binutils zlib1g-dev libbz2-dev cmake libboost-all-dev
RUN apt install -y g++-12
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 12 --slave /usr/bin/g++ g++ /usr/bin/g++-12
WORKDIR cmangos
RUN mkdir build run
RUN git clone https://github.com/cmangos/mangos-classic.git mangos
RUN git clone https://github.com/cmangos/classic-db.git
WORKDIR build
RUN cmake -DDEBUG=0 -DBUILD_EXTRACTORS=ON -DCMAKE_INSTALL_PREFIX=../run ../mangos
RUN make -j`nproc`
RUN make install
WORKDIR ..
COPY wow tmp
RUN mv run/bin/tools/* tmp
RUN rmdir run/bin/tools
WORKDIR tmp
RUN printf "8\ny\ny" | bash ExtractResources.sh a
RUN mv maps dbc Cameras vmaps mmaps ../run/bin
WORKDIR ..
RUN usermod -d /var/lib/mysql/ mysql
RUN service mysql start && mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'mang0sR00t_';"
RUN service mysql start && mysql -uroot -pmang0sR00t_ -e "FLUSH PRIVILEGES;"
RUN service mysql start && mysql -uroot -pmang0sR00t_ < mangos/sql/create/db_create_mysql.sql 
RUN service mysql start && mysql -uroot -pmang0sR00t_ classicmangos < mangos/sql/base/mangos.sql
RUN service mysql start && mysql -uroot -pmang0sR00t_ classiccharacters < mangos/sql/base/characters.sql
RUN service mysql start && mysql -uroot -pmang0sR00t_ classiclogs < mangos/sql/base/logs.sql
RUN service mysql start && mysql -uroot -pmang0sR00t_ classicrealmd < mangos/sql/base/realmd.sql
RUN service mysql start && printf "FORCE_WAIT=NO\nCORE_PATH=../mangos\nMYSQL=mysql\nMYSQL_PATH=mysql" > classic-db/InstallFullDB.config
RUN service mysql start && sed -i 's/MYSQL_COMMAND=.*/MYSQL_COMMAND="mysql classicmangos"/g' classic-db/InstallFullDB.sh
RUN service mysql start && cd classic-db && ./InstallFullDB.sh -World
RUN service mysql start && mysql -uroot -pmang0sR00t_ classicrealmd -e 'DELETE FROM realmlist WHERE id=1;'
RUN service mysql start && mysql -uroot -pmang0sR00t_ classicrealmd -e "INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel) VALUES ('1', 'MaNGOS', '10.30.0.210', '8085', '1', '0', '1', '0');"
RUN mv run/etc/mangosd.conf.dist run/etc/mangosd.conf
RUN mv run/etc/realmd.conf.dist run/etc/realmd.conf
RUN mv run/etc/anticheat.conf.dist run/etc/anticheat.conf

FROM ubuntu:jammy
COPY --from=builder /cmangos/run /cmangos
COPY --from=builder /var/lib/mysql /var/lib/mysql
RUN apt-get update && apt-get install -y mysql-server screen libmysql++-dev
WORKDIR cmangos/bin
#CMD if [ ! -d /var/lib/mysql/classicmangos ]; then rm -rf /var/lib/mysql/* && mv /var/lib/mysql_bak/* /var/lib/mysql/; fi && \
    #usermod -d /var/lib/mysql/ mysql && \
CMD service mysql start && \
    screen -dm bash -c "./mangosd" && \
    screen -dm bash -c "./realmd" && \
    sleep infinity
