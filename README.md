KIT-IT_infra
KIT-IT Infra repository
HW 3
bastion_IP = 178.154.203.200 someinternalhost_IP = 10.130.0.10

Connect to someinternalhost in one command: ssh -J appuser@130.193.44.187 appuser@10.128.0.28

Add /etc/ssh/ssh_config for connect to someinternalhost with hostname Host someinternalhost Hostname 178.154.203.200 Port 22 User appuser IdentityFile /home/kit/.ssh/appuser RemoteCommand ssh 10.130.0.10 RequestTTY force ForwardAgent yes
HW4
testapp_IP = 84.252.129.173 testapp_port = 9292

Настроили CLI Создали профиль Создали ВМ yc compute instance create
--name reddit-app
--hostname reddit-app
--memory=4
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4
--metadata serial-port-enable=1
--ssh-key ~/.ssh/appuser.pub Подключилсь к инстансу ssh yc-user@<instace_public_ip> Обновились и установили Руби и Бандлер sudo apt update sudo apt install -y ruby-full ruby-bundler build-essential Добавили ключи и репозиторий Монго wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add - echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodborg/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list Обновили индекс и установили необходимый пакет sudo apt-get update sudo apt-get install -y mongodb-org Запутили и добавили в автозапуск МонгоДБ. Проверили. sudo systemctl start mongod sudo systemctl enable mongod sudo systemctl status mongod Установили ГИТ sudo apt install git Скопировали код приложения Реддит git clone -b monolith https://github.com/express42/reddit.git Установили зависимости cd reddit && bundle install Задеплоили приложение puma -d Проверили что сервер запустился ps aux | grep puma Проверили через браузер http://84.252.129.173:9292/
HW5
Создали ветку packer-base git checkout -b packer-base Создали каталог и перенесли наработки из предыдущего задания yc config list

SVC_ACCT="appuser"

FOLDER_ID="b1g484bj5rqea9ljk25h"

yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID

ACCT_ID=$(yc iam service-account get $SVC_ACCT |
grep ^id |
awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID
--role editor
--service-account-id $ACCT_ID

yc iam key create --service-account-id $ACCT_ID --output ~/.ssh/key.json
id: aje1s7uhm1b1t84ldi25 service_account_id: aje4dauc0070fdkjp876 created_at: "2021-03-31T19:05:43.412384Z" key_algorithm: RSA_2048
Создали каталог packer и файл ubuntu16.json type - тип билдера - то, на какой платформе мы создаём образ folder_id - идентификатор каталога, в котором будет создан образ source_image_family - семейство образов, которое мы берём за основу. Packer самостоятельно выберет самый свежий образ. image_name - имя результирующего образа. В имени использована конструкция timestamp, которая гарантирует уникальность имени image_family - имя семейства, к которому мы отнесём результирующий образ ssh_username - имя пользователя, который будет использован для подключения к ВМ и выполнения provisioning'а platform_id - размер ВМ для образа

Проверили файл на валидность packer validate ./ubuntu16.json

Создали образ. Внимаение! В провиженеры добавили sleep 30, так как не успевали отрабатываться команды. packer build ./ubuntu16.json

Создали ВМ из образа на Yandex Cloud

Авторизовались в ВМ и усатновили Reddit sudo apt-get update sudo apt-get install -y git git clone -b monolith https://github.com/express42/reddit.git cd reddit && bundle install puma -d

Параметризовали файл.

Запекли кекс Immutable infrastructure
HW5 terraform-1
Создали ветку git checkout -b terraform-1 Создали каталог и файл main.tf. Добавили в gitignore служебные файлы. Добавили в main.tf. Данные из yc config list provider "yandex" { token = "AgAAAAAMleioAATuwaoO9CNZNkPmoNgTWTrv5vQ" cloud_id = "b1g6v5s594gnrffcntf6" folder_id = "b1g484bj5rqea9ljk25h" zone = "ru-central1-a" } Инициализировали terraform. terraform init Внесли данные по образам. yc compute image list resource "yandex_compute_instance" "app" { name = "reddit-app"

resources { cores = 1 memory = 2 } boot_disk { initialize_params { # Указать id образа созданного в предыдущем домашнем задании image_id = "fd8pdjeemi3e4akpq9vr" } } network_interface { # Указан id подсети default-ru-central1-a #subnet_id = "e9bem33uhju28r5i7pnu" subnet_id = "enpt8f7gqk9ogfi1p93u" nat = true } } Проверили валдность terraform plan Создали ВМ terraform apply Узнали ВМ ip terraform show | grep nat_ip_addres nat_ip_address = "84.201.175.134" Создали ключи для пользователя ubuntu ssh-keygen -t rsa -f /.ssh/ubuntu -C ubuntu -P "" Добавили в конфиг main.tf metadata = { ssh-keys = "ubuntu:${file("/.ssh/ubuntu.pub")}" } Создали файл outputs.tf Вынесли переменную ip инстанса для легкого поиска output "external_ip_address_app" { value = yandex_compute_instance.app.network_interface.0.nat_ip_address } yandex_compute_instance.app - инициализируем ресурс, указывая его тип и имя network_interface.0.nat_ip_address - указываем нужные атрибуты ресурса Используем команду terraform refresh, чтобы выходная переменная приняла значение. external_ip_address_app = 130.193.37.129 Значение выходных переменным можно посмотреть, используя команду terraform output: 130.193.37.129

Вставили provisioner provisioner "file" { source = "files/puma.service" destination = "/tmp/puma.service" } Создали директорию files и поместили puma.service с содержимым [Unit] Description=Puma HTTP Server After=network.target [Service] Type=simple User=ubuntu WorkingDirectory=/home/ubuntu/reddit ExecStart=/bin/bash -lc 'puma' Restart=always [Install] WantedBy=multi-user.target Добавили еще один provisioner provisioner "remote-exec" { script = "files/deploy.sh" } Создали files/deploy.sh c содержимым #!/bin/bash set -e APP_DIR=${1:-$HOME} sudo apt-get install -y git git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit cd $APP_DIR/reddit bundle install sudo mv /tmp/puma.service /etc/systemd/system/puma.service sudo systemctl start puma sudo systemctl enable puma Указали подключение connection { type = "ssh" host = yandex_compute_instance.app.network_interface.0.nat_ip_address user = "ubuntu" agent = false # путь до приватного ключа private_key = file("~/.ssh/ubuntu") } Terraform предлагает команду taint, которая позволяет пометить ресурс, который terraform должен пересоздать, при следующем запуске terraform apply. terraform taint yandex_compute_instance.app ok 22:59:15 Resource instance yandex_compute_instance.app has been marked as tainted. Планируем изменения terraform plan Создаем новый инстанст terraform apply Сервисный аккаунт id: ajeb6f5t16d3r6o9lihg service_account_id: aje4dauc0070fdkjp876 created_at: "2021-04-13T20:53:49.455685031Z" key_algorithm: RSA_2048
HW6 terraform-2
access_key: id: ajeschgo3fd292ha2v71 service_account_id: aje4dauc0070fdkjp876 created_at: "2021-04-22T20:43:17.738201478Z" description: this key is for my bucket key_id: jM2KZWCKeDxEIM6mp_Av secret: yuTfyBQRLn6rt5olC5aI0cnqU_r0o2shaFwEz9gn

Создали образы для бд и приложения. Создали модули. Какую же я боль испытал, когда terraform при инициализации модулей подхватил конфиграцию, в которой была ошибка и че бы я не делал, все равно не хотел менять на обновленный. В итоге залез внутрь терраформа и поправил ручкаи. Все заработало. Какашка!!! Использовали бакет в яндексе для хранения состояния вм. Смогли перенсти конфиграцию без стейста, стейт подхватывается из бакета.
HW7 ansible-1
Установили ansible, python, pip Создали каталог ansible Создали два инстанца (DB, APP) при помощи terraform Занесли данные в файл inventory appserver ansible_host=178.154.200.46 ansible_user=ubuntu ansible_private_key_file=/.ssh/ubuntu Проверили доступность тачки ansible ansible-1 !8 ?1 ansible appserver -i ./inventory -m ping ok 19:23:36 The authenticity of host '178.154.200.46 (178.154.200.46)' can't be established. ECDSA key fingerprint is SHA256:xE9kYt9sp7Ph7z100bJNPoiexS9lyH9Nk1EBo1N/isI. ECDSA key fingerprint is MD5:26:95:45:a2:2f:78:be:db:dd:59:d2:c6:84:ee🆎fb. Are you sure you want to continue connecting (yes/no)? yes appserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "changed": false, "ping": "pong" } -m ping - вызываемый модуль -i ./inventory - путь до файла инвентори appserver - Имя хоста, которое указали в инвентори, откуда Ansible yзнает, как подключаться к хосту Опредили в inventory dbserver dbserver ansible_host=178.154.201.81 ansible_user=ubuntu ansible_private_key_file=/.ssh/ubuntu Проверили доступность ansible ansible-1 !8 ?1 ansible dbserver -i inventory -m ping INT 19:29:10 The authenticity of host '178.154.201.81 (178.154.201.81)' can't be established. ECDSA key fingerprint is SHA256:D+IpFXshy3zA1tQXuWNJ/6gxjZjvjJzt56TXXjiLRmI. ECDSA key fingerprint is MD5:dc:9c:b0:c3:49:24:4e:73:1e:1a:f5:47:48:a1:e3:94. Are you sure you want to continue connecting (yes/no)? yes dbserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "changed": false, "ping": "pong" } Создали конфигурационный файл ansible.cfg [defaults] inventory = ./inventory remote_user = ubuntu private_key_file = ~/.ssh/ubuntu host_key_checking = False retry_files_enabled = False Inventory файл получился проще appserver ansible_host=178.154.200.46 dbserver ansible_host=178.154.201.81 Используем модуль command , который позволяет запускать произвольные команды на удаленном хосте. Выполним команду uptime для проверки времени работы инстанса. Команду передадим как аргумент для данного модуля, использовав опцию -a : ansible ansible-1 !8 ?1 ansible dbserver -m command -a uptime ok 19:32:42 dbserver | CHANGED | rc=0 >> 16:36:37 up 14 min, 1 user, load average: 0.00, 0.00, 0.00 Работа с группами хостов В инвентори файле мы можем определить группу хостов для управления конфигурацией сразу нескольких хостов. [app] # ⬅ Это название группы ppserver ansible_host=178.154.200.46 # ⬅ Cписок хостов в данной группе [db] dbserver ansible_host=178.154.201.81 Проверим работу ansible ansible-1 !8 ?1 ansible app -m ping ok 19:36:37 ppserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "changed": false, "ping": "pong" } app - имя группы -m ping - имя модуля Ansible appserver - имя сервера в группе, для которого применился модуль Создали файл inventory.yml и перенесли настройки из inventory- https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html Проверили работоспособность

ansible ansible-1 !8 ?1 ansible all -m ping -i inventory.yml ok 19:40:21 ppserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "changed": false, "ping": "pong" } dbserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "changed": false, "ping": "pong" } Проверим, что на app сервере установлены компоненты для работы приложения ( ruby и bundler ): ansible ansible-1 !8 ?1 ansible app -m command -a 'ruby -v' ok 19:41:09 ppserver | CHANGED | rc=0 >> ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu] ansible ansible-1 !8 ?1 ansible app -m command -a 'bundler -v' ok 19:42:52 ppserver | CHANGED | rc=0 >> Bundler version 1.11.2 Через модуль shell можно запросить сразу две команды ansible ansible-1 !8 ?1 ansible app -m shell -a 'ruby -v; bundler -v' 2 err 19:43:33 ppserver | CHANGED | rc=0 >> ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu] Bundler version 1.11.2 Так же проверили работу в dbserver ansible ansible-1 !8 ?1 ansible db -m command -a 'systemctl status mongod' ok 19:44:06 dbserver | CHANGED | rc=0 >> ● mongod.service - High-performance, schema-free document-oriented database Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled) Active: active (running) since Wed 2021-04-28 16:22:33 UTC; 22min ago Docs: https://docs.mongodb.org/manual Main PID: 637 (mongod) CGroup: /system.slice/mongod.service └─637 /usr/bin/mongod --quiet --config /etc/mongod.conf

Apr 28 16:22:33 fhm85al4f0mh48nhcjoi systemd[1]: Started High-performance, schema-free document-oriented database. ansible ansible-1 !8 ?1 ansible db -m shell -a 'systemctl status mongod' ok 19:44:54 dbserver | CHANGED | rc=0 >> ● mongod.service - High-performance, schema-free document-oriented database Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled) Active: active (running) since Wed 2021-04-28 16:22:33 UTC; 22min ago Docs: https://docs.mongodb.org/manual Main PID: 637 (mongod) CGroup: /system.slice/mongod.service └─637 /usr/bin/mongod --quiet --config /etc/mongod.conf

Apr 28 16:22:33 fhm85al4f0mh48nhcjoi systemd[1]: Started High-performance, schema-free document-oriented database. Так же можно использовать модуль systemd ansible db -m systemd -a name=mongod - результат длинный, все не буду вписывать ansible ansible-1 !8 ?1 ansible db -m systemd -a name=mongod ok 19:45:28 dbserver | SUCCESS => { "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, ... А еще вот так можно ansible db -m service -a name=mongod Далее команда не выполнялась, так как на ВМ не установлен GIT. Усатновил. Вообще надо бы что бы автоматом, в идеале в образ запихнуть или терраформом запустить провиженер. ЧТо то я пропустил кажется! ansible ansible-1 !8 ?1 ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit' ppserver | CHANGED => { "after": "5c217c565c1122c5343dc0514c116ae816c17ca2", "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "before": null, "changed": true } Вторая команда ansible ansible-1 !8 ?1 ansible app -m git -a \ ok 4s 19:57:39 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit' ppserver | SUCCESS => { "after": "5c217c565c1122c5343dc0514c116ae816c17ca2", "ansible_facts": { "discovered_interpreter_python": "/usr/bin/python3" }, "before": "5c217c565c1122c5343dc0514c116ae816c17ca2", "changed": false, "remote_url_changed": false } Как мы видим, повторное выполнение этой команды проходит успешно, только переменная changed будет false (что значит, что изменения не произошли) Плейбук. Звучит как порно. Создали файл ansible/clone.yml
name: Clone hosts: app tasks:
name: Clone repo git: repo: https://github.com/express42/reddit.git dest: /home/ubuntu/reddit ansible ansible-1 !8 ?1 ansible-playbook clone.yml ok 20:01:10
PLAY [Clone] ****************************************************************************************

TASK [Gathering Facts] ****************************************************************************** ok: [ppserver]

TASK [Clone repo] *********************************************************************************** ok: [ppserver]

PLAY RECAP ****************************************************************************************** ppserver : ok=2 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 Напишем простой плейбук Мы удалил то что загрузили и снова загрузили.
HW8 ansible-2
Создали плейбук ansible/reddit_app.yml
name: Configure hosts & deploy application # <-- Словесное описание сценария (name) hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts) tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
name: Change mongo config file become: true # <-- Выполнить задание от root template: src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона dest: /etc/mongod.conf # <-- Путь на удаленном хосте mode: 0644 # <-- Права на файл, которые нужно установить tags: db-tag # <-- Список тэгов для задачи Создали шаблон конфига templates/mongod.conf.j2
Where and how to store data.
storage: dbPath: /var/lib/mongodb journal: enabled: true

where to write logging data.
systemLog: destination: file logAppend: true path: /var/log/mongodb/mongod.log

network interfaces
net: port: {{ mongo_port | default('27017') }} bindIp: {{ mongo_bind_ip }} Пробный прогон ansible ansible-2 !8 ?2 ansible-playbook reddit-app.yml --check --limit db 2 err 22:23:28

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************** ok: [dbserver]

TASK [Change mongo config file] ***************************************************************************************************************************************************************************** fatal: [dbserver]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: 'mongo_bind_ip' is undefined"}

PLAY RECAP ************************************************************************************************************************************************************************************************** dbserver : ok=1 changed=0 unreachable=0 failed=1 skipped=0 rescued=0 ignored=0 AnsibleUndefinedVariable - Ошибка❗ Переменная, которая используется в шаблоне не определена Задали переменную в плейбуке vars: mongo_bind_ip: 0.0.0.0 Снова прогон ansible ansible-2 !8 ?2 ansible-playbook reddit-app.yml --check --limit db 2 err 5s 22:23:46

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************** ok: [dbserver]

TASK [Change mongo config file] ***************************************************************************************************************************************************************************** changed: [dbserver]

PLAY RECAP ************************************************************************************************************************************************************************************************** dbserver : ok=2 changed=1 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Handlers Handlers похожи на таски, однако запускаются только по оповещению от других задач. Таск шлет оповещение handler-у в случае, когда он меняет свое состояние. По этой причине handlers удобно использовать для перезапуска сервисов. Изменение конфигурационного файла MongoDВ требует от нас перезапуска БД для применения конфигурации. Используем для этой задачи handler. Определим handler для рестарта БД и добавим вызов handler-а в созданный нами таск. Добавили к плейбуку notify: restart mongod handlers: # <-- Добавим блок handlers и задачу - name: restart mongod become: true service: name=mongod state=restarted Прогнали ansible ansible-2 !8 ?2 ansible-playbook reddit-app.yml --check --limit db INT 22:27:38

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************** ok: [dbserver]

TASK [Change mongo config file] ***************************************************************************************************************************************************************************** changed: [dbserver]

RUNNING HANDLER [restart mongod] **************************************************************************************************************************************************************************** changed: [dbserver]

PLAY RECAP ************************************************************************************************************************************************************************************************** dbserver : ok=3 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Запустили ansible ansible-2 !8 ?2 ansible-playbook reddit-app.yml --limit db ok 8s 22:32:25

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************** ok: [dbserver]

TASK [Change mongo config file] ***************************************************************************************************************************************************************************** changed: [dbserver]

RUNNING HANDLER [restart mongod] **************************************************************************************************************************************************************************** changed: [dbserver]

PLAY RECAP ************************************************************************************************************************************************************************************************** dbserver : ok=3 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Настройка инстанса приложения Добавили файл touch files/puma.service [Unit] Description=Puma HTTP Server After=network.target

[Service] Type=simple EnvironmentFile=/home/appuser/db_config User=appuser WorkingDirectory=/home/appuser/reddit ExecStart=/bin/bash -lc 'puma' Restart=always

[Install] WantedBy=multi-user.target Добавили задача и в плейбук, не забываем о хендлерах.
name: Configure hosts & deploy application # <-- Словесное описание сценария (name) hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts) vars: mongo_bind_ip: 0.0.0.0 tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов

name: Change mongo config file become: true # <-- Выполнить задание от root template: src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона dest: /etc/mongod.conf # <-- Путь на удаленном хосте mode: 0644 # <-- Права на файл, которые нужно установить tags: db-tag # <-- Список тэгов для задачи notify: restart mongod

name: Add unit file for Puma become: true copy: src: files/puma.service dest: /etc/systemd/system/puma.service tags: app-tag notify: reload puma

name: enable puma become: true systemd: name=puma enabled=yes tags: app-tag

handlers: # <-- Добавим блок handlers и задачу

name: restart mongod become: true service: name=mongod state=restarted
name: reload puma become: true systemd: name=puma state=restarted
Создали еще один шаблон templates/db_config.j2 DATABASE_URL={{ db_host }} Добавили переменную в плейбук db_host: 10.132.0.2 для видимости инстанса Прогнали ansible ansible-2 !9 ?3 ansible-playbook reddit-app.yml --check --limit app --tags app-tag

PLAY [Configure hosts & deploy application] *********************************************************

TASK [Gathering Facts] ****************************************************************************** ok: [appserver]

TASK [Add unit file for Puma] *********************************************************************** ok: [appserver]

TASK [Add config for DB connection] ***************************************************************** ok: [appserver]

TASK [enable puma] ********************************************************************************** ok: [appserver]

PLAY RECAP ****************************************************************************************** appserver : ok=4 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Деплой Добавим еще несколько тасков в сценарий нашего плейбука. Используем модули git и bundle для клонирования последней версии кода нашего приложения и установки зависимых Ruby Gems через bundle . Добавили в конфиг - name: Fetch the latest version of application code git: repo: 'https://github.com/express42/reddit.git' dest: /home/appuser/reddit version: monolith # <-- Указываем нужную ветку tags: deploy-tag notify: reload puma

- name: Bundle install
  bundler:
    state: present
    chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle
  tags: deploy-tag
Проверили ansible ansible-2 !9 ?3 ansible-playbook reddit-app.yml --limit app --tags deploy-tag

PLAY [Configure hosts & deploy application] *********************************************************

TASK [Gathering Facts] ****************************************************************************** ok: [appserver]

TASK [Fetch the latest version of application code] ************************************************* ok: [appserver]

TASK [Bundle install] ******************************************************************************* changed: [appserver]

PLAY RECAP ****************************************************************************************** appserver : ok=3 changed=1 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Приложение поднялось. Разнесли БД и Приложение на разные деплои. Пересоздали инстансы через терраформ. ansible ansible-2 +13 !3 ?1 ansible-playbook reddit_app2.yml --tags db-tag

PLAY [Configure MongoDB] **************************************************************

TASK [Gathering Facts] **************************************************************** ok: [dbserver]

TASK [Change mongo config file] ******************************************************* changed: [dbserver]

RUNNING HANDLER [restart mongod] ****************************************************** changed: [dbserver]

PLAY [Configure App] ******************************************************************

PLAY RECAP **************************************************************************** dbserver : ok=3 changed=2 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 ansible ansible-2 +13 !3 ?1 ansible-playbook reddit_app2.yml --tags app-tag

PLAY [Configure MongoDB] **************************************************************

PLAY [Configure App] ******************************************************************

TASK [Gathering Facts] **************************************************************** ok: [appserver]

TASK [Add unit file for Puma] ********************************************************* changed: [appserver]

TASK [Add config for DB connection] *************************************************** changed: [appserver]

TASK [enable puma] ******************************************************************** changed: [appserver]

RUNNING HANDLER [reload puma] ********************************************************* changed: [appserver]

PLAY RECAP **************************************************************************** appserver : ok=5 changed=4 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Добавили деплой Так же добавили установку гита - name: Install git apt: name: git state: present update_cache: yes ansible ansible-2 +13 !3 ?1 ansible-playbook reddit_app2.yml --tags deploy-tag

PLAY [Configure MongoDB] **************************************************************

PLAY [Configure App] ******************************************************************

PLAY [Deploy App] *********************************************************************

TASK [Gathering Facts] **************************************************************** ok: [appserver]

TASK [Install git] ******************************************************************** ok: [appserver]

TASK [Fetch the latest version of application code] *********************************** ok: [appserver]

TASK [bundle install] ***************************************************************** ok: [appserver]

PLAY RECAP **************************************************************************** appserver : ok=4 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 Приложение поднялось на верх Несколько плейбуков Разнесли деплой на разные ямл. Все сценарии обозначили в site.yml запустились и ОК ansible ansible-2 +13 !3 ?1 ansible-playbook site.yml INT 20:20:42

PLAY [Configure mongod] ***************************************************************

TASK [Gathering Facts] **************************************************************** ok: [dbserver]

TASK [Change mongo config file] ******************************************************* changed: [dbserver]

RUNNING HANDLER [restart mongod] ****************************************************** changed: [dbserver]

PLAY [Configure app] ******************************************************************

TASK [Gathering Facts] **************************************************************** ok: [appserver]

TASK [Add unit file for Puma] ********************************************************* changed: [appserver]

TASK [Add config for DB connection] *************************************************** changed: [appserver]

TASK [enable puma] ******************************************************************** changed: [appserver]

RUNNING HANDLER [reload puma] ********************************************************* changed: [appserver]

PLAY [Deploy App] *********************************************************************

TASK [Gathering Facts] **************************************************************** ok: [appserver]

TASK [insatall git] ******************************************************************* changed: [appserver]

TASK [Fetch the latest version of application code] *********************************** changed: [appserver]

TASK [bundle install] ***************************************************************** changed: [appserver]

RUNNING HANDLER [restart puma] ******************************************************** changed: [appserver]

PLAY RECAP **************************************************************************** appserver : ok=10 changed=8 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0 dbserver : ok=3 changed=2 unreachable=0 failed=0 skipped=0
-------
HW9 ansible-3
-------
Роли для приложений
Создали каталог roles
KIT-IT_infra  ansible-3  cd ansible                              1 err  3s  21:59:59
 ansible  ansible-3  mkdir roles                                         ok  22:00:07
 ansible  ansible-3  cd roles                                            ok  22:03:24
 roles  ansible-3  ansible-galaxy init app                               ok  22:03:31
- Role app was created successfully
 roles  ansible-3 ?1  ansible-galaxy init db                             ok  22:03:41
- Role db was created successfully
 roles  ansible-3 ?1  ls                                                 ok  22:03:47
app  db
 roles  ansible-3 ?1  tree db                                            ok  22:03:49
db
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

8 directories, 8 files
Создадим роль для конфигурации MongoDB:
Опредилили шаблоны, таски, хендлеры для апп и дб инстансов.
Вызовы ролей
Переколхозили инстансы через терраформ.
Запустили плейбуки, должно приложение подняться на верх. ОК.
Окружения
 ansible  ansible-3 !4 ?1  mkdir environments                       ok  47s  22:25:48
 ansible  ansible-3 !4 ?1  cd environments                               ok  22:33:29
 environments  ansible-3 !4 ?1  mkdir stage prod
Скопируем инвентори файл ansible/inventory в каждую из
директорий окружения и удалим из ansible/
Теперь будем использовать так ansible-playbook -i environments/prod/inventory deploy.yml
Определим окружение по умолчанию в конфиге Ansible (файл ansible/ansible.cfg):
defaults]
inventory = ./environments/stage/inventory # Inventory по-умолчанию задается здесь
remote_user = appuser
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
Переменные групп хостов
Ansible позволяет задавать переменные для групп хостов, определенных в инвентори файле. Воспользуемся этим для управления настройками окружений.
 environments  ansible-3 !5 ?3  mkdir prod/group_vars stage/group_vars   ok  22:40:31
 environments  ansible-3 !5 ?3  touch stage/group_vars/app               ok  22:41:10
 environments  ansible-3 !5 ?3  touch prod/group_vars/app
Добавили переменные в app из ansible/app.yml
environments  ansible-3 !5 ?3  touch prod/group_vars/db                 ok  22:42:27
 environments  ansible-3 !5 ?3  touch stage/group_vars/db
Добавили переменные в db из ansible/db.yml
 environments  ansible-3 !5 ?3  mkdir prod/group_vars stage/group_vars   ok  22:40:31
 environments  ansible-3 !5 ?3  touch stage/group_vars/app               ok  22:41:10
 environments  ansible-3 !5 ?3  touch prod/group_vars/app                ok  22:42:22
 environments  ansible-3 !5 ?3  touch prod/group_vars/db                 ok  22:42:27
 environments  ansible-3 !5 ?3  touch stage/group_vars/db                ok  22:44:12
 environments  ansible-3 !5 ?3  touch stage/group_vars/all               ok  22:44:16
 environments  ansible-3 !5 ?2  touch stage/group_vars/all >> env: stage
 environments  ansible-3 !5 ?2  cp stage/group_vars/all prod/group_vars  ok  22:48:23
 environments  ansible-3 !5 ?2
Вывод информации об окружении
Для хостов из каждого окружения мы определили переменную
env, которая содержит название окружения.
Теперь настроим вывод информации об окружении, с которым
мы работаем, при применении плейбуков.
Определим переменную по умолчанию env в используемых
ролях...
Добавили ansible/roles/app/defaults/main.yml env: local, как и для db
Будем выводить информацию о том, в каком окружении
находится конфигурируемый хост. Воспользуемся модулем debug
для вывода значения переменной. Добавим следующий таск в
начало наших ролей.
Добавили в ansible/roles/app/tasks/main.yml и ansible/roles/db/tasks/main.yml дебаг сообщение для вывода
Организуем плейбуки
Перенесем все плейбуки в отдельную директорию согласно best practices:
Почистили каталоги
Улучшии ansible.cfg
[defaults]
inventory = ./environments/stage/inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
# Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# # Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles
[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
ansible  ansible-3 !15 ?4  ansible-playbook playbooks/site.yml
Приложение поднялось наверх
Настройка Prod окружения
Пересоздали инстансы через терраформ, подставили все айпи в инветори прода и запустили
 ansible  ansible-3 !15 ?4   ansible-playbook -i environments/prod/inventory playbooks/site.yml
Приложение поднялось наверх
Работа с Community-ролями
Используем роль jdauphant.nginx и настроим обратное проксирование для нашего приложения с помощью nginx.
Создадим файлы environments/stage/requirements.yml и environments/prod/requirements.yml
 ansible  ansible-3 !15 ?4  ansible-galaxy install -r environments/stage/requirements.yml
Starting galaxy role install process
- downloading role 'nginx', owned by jdauphant
- downloading role from https://github.com/jdauphant/ansible-role-nginx/archive/v2.21.1.tar.gz
- extracting jdauphant.nginx to /home/kit/Desktop/GIT/OTUS2/KIT-IT_infra/ansible/roles/jdauphant.nginx
- jdauphant.nginx (v2.21.1) was installed successfully
Добавили вызов роли jdauphant.nginx
Передеплоились, приложение теперь доступно на 80 и 9292 портах.
Самостоятельное задание выполнено.
Работа с Ansible Vault
 ansible  ansible-3 !16 ?4  touch environments/stage/credentials.yml
 ansible  ansible-3 !16 ?4  touch environments/stage/vault.key
Добавили в ansible.cfg
[defaults]
...
vault_password_file = vault.key
ansible  ansible-3 !16 ?4  ansible-vault encrypt environments/prod/credentials.yml
Encryption successful
ansible  ansible-3 !16 ?4  ansible-vault encrypt environments/stage/credentials.yml  INT  22:44:20
Encryption successful
Добавили плейбук в вызов к остальным
Запустили и провели успешный вход по тестовыми УЗ
 stage  ansible-3 !16 ?4  ssh qauser@178.154.204.120                                   ok  22:04:00
qauser@178.154.204.120's password:
Permission denied, please try again.
qauser@178.154.204.120's password:
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)
P.S.
Для редактирования переменных нужно использовать
команду ansible-vault edit <file>
А для расшифровки: ansible-vault decrypt <file>
