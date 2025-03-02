# cmangos-classic-docker
 Dockerized instance of cMangos Classic

Change the IP address on line 35 of the Dockerfile to the IP address of your server (usually a LAN IP address).

To start the server, make sure you have the files of a complete WoW vanilla client (v1.12.1) in a directory called "wow" in the same directory as the Dockerfile. Then run the following commands:
`docker-compose build
docker-compose up`