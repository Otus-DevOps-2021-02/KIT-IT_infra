# KIT-IT_infra
KIT-IT Infra repository

HW 3

bastion_IP = 178.154.203.200
someinternalhost_IP = 10.130.0.10

Connect to someinternalhost in one command:
ssh -J appuser@130.193.44.187 appuser@10.128.0.28

Add /etc/ssh/ssh_config for connect to someinternalhost with hostname
Host someinternalhost
Hostname 178.154.203.200
Port 22
User appuser
IdentityFile /home/kit/.ssh/appuser
RemoteCommand ssh 10.130.0.10
RequestTTY force
ForwardAgent yes
