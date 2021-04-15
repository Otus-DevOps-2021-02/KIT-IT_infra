# KIT-IT_infra
KIT-IT Infra repository
-----------------------------
HW 3
-----------------------------
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
------------------------------
HW4
------------------------------
testapp_IP = 84.252.129.173
testapp_port = 9292

Настроили CLI
Создали профиль
Создали ВМ
    yc compute instance create \
    --name reddit-app \
    --hostname reddit-app \
    --memory=4 \
    --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
    --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
    --metadata serial-port-enable=1 \
    --ssh-key ~/.ssh/appuser.pub
Подключилсь к инстансу
    ssh yc-user@<instace_public_ip>
Обновились и установили Руби и Бандлер
    sudo apt update
    sudo apt install -y ruby-full ruby-bundler build-essential
Добавили ключи и репозиторий Монго
    wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodborg/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
Обновили индекс и установили необходимый пакет
    sudo apt-get update
    sudo apt-get install -y mongodb-org
Запутили и добавили в автозапуск МонгоДБ. Проверили.
    sudo systemctl start mongod
    sudo systemctl enable mongod
    sudo systemctl status mongod
Установили ГИТ
    sudo apt install git
Скопировали код приложения Реддит
    git clone -b monolith https://github.com/express42/reddit.git
Установили зависимости
    cd reddit && bundle install
Задеплоили приложение
    puma -d
Проверили что сервер запустился
    ps aux | grep puma
Проверили через браузер
    http://84.252.129.173:9292/

------------------------------
HW5
------------------------------
Создали ветку packer-base
git checkout -b packer-base
Создали каталог и перенесли наработки из предыдущего задания
yc config list

SVC_ACCT="appuser"

FOLDER_ID="b1g484bj5rqea9ljk25h"

yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID

ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | \
awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID

yc iam key create --service-account-id $ACCT_ID --output ~/.ssh/key.json
---
id: aje1s7uhm1b1t84ldi25
service_account_id: aje4dauc0070fdkjp876
created_at: "2021-03-31T19:05:43.412384Z"
key_algorithm: RSA_2048
---

Создали каталог packer и файл ubuntu16.json
type - тип билдера - то, на какой платформе мы создаём образ
folder_id - идентификатор каталога, в котором будет создан
образ
source_image_family - семейство образов, которое мы берём за
основу. Packer самостоятельно выберет самый свежий образ.
image_name - имя результирующего образа. В имени
использована конструкция timestamp, которая гарантирует
уникальность имени
image_family - имя семейства, к которому мы отнесём
результирующий образ
ssh_username - имя пользователя, который будет использован
для подключения к ВМ и выполнения provisioning'а
platform_id - размер ВМ для образа

Проверили файл на валидность
packer validate ./ubuntu16.json

Создали образ. Внимаение! В провиженеры добавили sleep 30, так как не успевали отрабатываться команды.
packer build ./ubuntu16.json

Создали ВМ из образа на Yandex Cloud

Авторизовались в ВМ и усатновили Reddit
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d

Параметризовали файл.

Запекли кекс Immutable infrastructure
