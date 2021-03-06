#!/bin/bash
sleep 10
apt-get update
sleep 30
apt-get install apt-transport-https
sleep 30
apt-get install gnupg
sleep 30
echo "wget -qO - https://www.mongodb.org/static/pgp/server-3.2.asc"
wget -qO - https://www.mongodb.org/static/pgp/server-3.2.asc | sudo apt-key add - # После пайпа sudo не убрано - а то не отработает добавление ключа
sleep 30
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sleep 30
echo "apt-get update"
apt-get update
sleep 50
echo "apt install -y mongodb-org"
apt install -y mongodb-org
sleep 30
echo "systemctl start mongod"
systemctl start mongod
systemctl enable mongod
