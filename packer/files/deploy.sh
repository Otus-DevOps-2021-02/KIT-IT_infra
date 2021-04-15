#!/bin/bash
cd /home/ubuntu
apt install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
mv /home/ubuntu/reddit.service /etc/systemd/system/reddit.service
chmod 644 /etc/systemd/system/reddit.service
chmod a+x /home/ubuntu/start-reddit.sh
systemctl start reddit
systemctl enable reddit
systemctl status reddit
