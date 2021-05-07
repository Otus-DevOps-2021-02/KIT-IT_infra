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
HW5 terraform-1
------------------------------
Создали ветку
git checkout -b terraform-1
Создали каталог и файл main.tf. Добавили в gitignore служебные файлы.
Добавили в main.tf. Данные из yc config list
provider "yandex" {
  token     = "AgAAAAAMleioAATuwaoO9CNZNkPmoNgTWTrv5vQ"
  cloud_id  = "b1g6v5s594gnrffcntf6"
  folder_id = "b1g484bj5rqea9ljk25h"
  zone      = "ru-central1-a"
}
Инициализировали terraform.
terraform init
Внесли данные по образам. yc compute image list
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores = 1
    memory = 2
  }
  boot_disk {
    initialize_params {
        # Указать id образа созданного в предыдущем домашнем задании
        image_id = "fd8pdjeemi3e4akpq9vr"
    }
  }
  network_interface {
    # Указан id подсети default-ru-central1-a
    #subnet_id = "e9bem33uhju28r5i7pnu"
    subnet_id = "enpt8f7gqk9ogfi1p93u"
    nat = true
  }
}
Проверили валдность
terraform plan
Создали ВМ
terraform apply
Узнали ВМ ip
terraform show | grep nat_ip_addres
nat_ip_address     = "84.201.175.134"
Создали ключи для пользователя ubuntu
ssh-keygen -t rsa -f ~/.ssh/ubuntu -C ubuntu -P ""
Добавили в конфиг main.tf
metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
}
Создали файл outputs.tf
Вынесли переменную ip инстанса для легкого поиска
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
yandex_compute_instance.app - инициализируем ресурс,
указывая его тип и имя
network_interface.0.nat_ip_address - указываем нужные
атрибуты ресурса
Используем команду terraform refresh, чтобы выходная
переменная приняла значение.
external_ip_address_app = 130.193.37.129
Значение выходных переменным можно посмотреть, используя
команду terraform output:
130.193.37.129

Вставили provisioner
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
Создали директорию files и поместили puma.service с содержимым
[Unit]
Description=Puma HTTP Server
After=network.target
[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
[Install]
WantedBy=multi-user.target
Добавили еще один provisioner
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
Создали files/deploy.sh c содержимым
#!/bin/bash
set -e
APP_DIR=${1:-$HOME}
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
Указали подключение
  connection {
    type = "ssh"
    host = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file("~/.ssh/ubuntu")
  }
Terraform предлагает команду taint, которая позволяет пометить
ресурс, который terraform должен пересоздать, при следующем
запуске terraform apply.
terraform taint yandex_compute_instance.app      ok  22:59:15
Resource instance yandex_compute_instance.app has been marked as tainted.
Планируем изменения
terraform plan
Создаем новый инстанст
terraform apply
Сервисный аккаунт
id: ajeb6f5t16d3r6o9lihg
service_account_id: aje4dauc0070fdkjp876
created_at: "2021-04-13T20:53:49.455685031Z"
key_algorithm: RSA_2048
--------
HW6 terraform-2
--------
access_key:
  id: ajeschgo3fd292ha2v71
  service_account_id: aje4dauc0070fdkjp876
  created_at: "2021-04-22T20:43:17.738201478Z"
  description: this key is for my bucket
  key_id: jM2KZWCKeDxEIM6mp_Av
secret: yuTfyBQRLn6rt5olC5aI0cnqU_r0o2shaFwEz9gn


Создали образы для бд и приложения.
Создали модули. Какую же я боль испытал, когда terraform при инициализации модулей подхватил конфиграцию, в которой была ошибка и че бы я не делал, все равно не хотел менять на обновленный. В итоге залез внутрь терраформа и поправил ручкаи. Все заработало. Какашка!!!
Использовали бакет в яндексе для хранения состояния вм.
Смогли перенсти конфиграцию без стейста, стейт подхватывается из бакета.
--------
HW7 ansible-1
--------
Установили ansible, python, pip
Создали каталог ansible
Создали два инстанца (DB, APP) при помощи terraform
Занесли данные в файл inventory
appserver ansible_host=178.154.200.46 ansible_user=ubuntu ansible_private_key_file=~/.ssh/ubuntu
Проверили доступность тачки
 ansible  ansible-1 !8 ?1  ansible appserver -i ./inventory -m ping                    ok  19:23:36
The authenticity of host '178.154.200.46 (178.154.200.46)' can't be established.
ECDSA key fingerprint is SHA256:xE9kYt9sp7Ph7z100bJNPoiexS9lyH9Nk1EBo1N/isI.
ECDSA key fingerprint is MD5:26:95:45:a2:2f:78:be:db:dd:59:d2:c6:84:ee:ab:fb.
Are you sure you want to continue connecting (yes/no)? yes
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
-m ping - вызываемый модуль
-i ./inventory - путь до файла инвентори
appserver - Имя хоста, которое указали в инвентори, откуда Ansible yзнает, как подключаться к хосту
Опредили в inventory dbserver
dbserver ansible_host=178.154.201.81 ansible_user=ubuntu ansible_private_key_file=~/.ssh/ubuntu
Проверили доступность
 ansible  ansible-1 !8 ?1  ansible dbserver -i inventory -m ping                      INT  19:29:10
The authenticity of host '178.154.201.81 (178.154.201.81)' can't be established.
ECDSA key fingerprint is SHA256:D+IpFXshy3zA1tQXuWNJ/6gxjZjvjJzt56TXXjiLRmI.
ECDSA key fingerprint is MD5:dc:9c:b0:c3:49:24:4e:73:1e:1a:f5:47:48:a1:e3:94.
Are you sure you want to continue connecting (yes/no)? yes
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
Создали конфигурационный файл ansible.cfg
[defaults]
inventory = ./inventory
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False
Inventory файл получился проще
appserver ansible_host=178.154.200.46
dbserver ansible_host=178.154.201.81
Используем модуль command , который позволяет запускать произвольные команды на удаленном хосте.
Выполним команду uptime для проверки времени работы инстанса.
Команду передадим как аргумент для данного модуля, использовав опцию -a :
ansible  ansible-1 !8 ?1  ansible dbserver -m command -a uptime                       ok  19:32:42
dbserver | CHANGED | rc=0 >>
16:36:37 up 14 min,  1 user,  load average: 0.00, 0.00, 0.00
Работа с группами хостов
В инвентори файле мы можем определить группу хостов для управления конфигурацией сразу нескольких хостов.
[app]  # ⬅ Это название группы
ppserver ansible_host=178.154.200.46 # ⬅ Cписок хостов в данной группе
[db]
dbserver ansible_host=178.154.201.81
Проверим работу
 ansible  ansible-1 !8 ?1  ansible app -m ping                                         ok  19:36:37
ppserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
app - имя группы
-m ping - имя модуля Ansible
appserver - имя сервера в группе, для которого применился модуль
Создали файл inventory.yml и перенесли настройки из inventory- https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html
Проверили работоспособность

 ansible  ansible-1 !8 ?1  ansible all -m ping -i inventory.yml                        ok  19:40:21
ppserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
Проверим, что на app сервере установлены компоненты для работы приложения ( ruby и bundler ):
 ansible  ansible-1 !8 ?1  ansible app -m command -a 'ruby -v'                         ok  19:41:09
ppserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
 ansible  ansible-1 !8 ?1  ansible app -m command -a 'bundler -v'                      ok  19:42:52
ppserver | CHANGED | rc=0 >>
Bundler version 1.11.2
Через модуль shell можно запросить сразу две команды
 ansible  ansible-1 !8 ?1  ansible app -m shell -a 'ruby -v; bundler -v'            2 err  19:43:33
ppserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 1.11.2
Так же проверили работу в dbserver
 ansible  ansible-1 !8 ?1  ansible db -m command -a 'systemctl status mongod'          ok  19:44:06
dbserver | CHANGED | rc=0 >>
● mongod.service - High-performance, schema-free document-oriented database
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-04-28 16:22:33 UTC; 22min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 637 (mongod)
   CGroup: /system.slice/mongod.service
           └─637 /usr/bin/mongod --quiet --config /etc/mongod.conf

Apr 28 16:22:33 fhm85al4f0mh48nhcjoi systemd[1]: Started High-performance, schema-free document-oriented database.
 ansible  ansible-1 !8 ?1  ansible db -m shell -a 'systemctl status mongod'            ok  19:44:54
dbserver | CHANGED | rc=0 >>
● mongod.service - High-performance, schema-free document-oriented database
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-04-28 16:22:33 UTC; 22min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 637 (mongod)
   CGroup: /system.slice/mongod.service
           └─637 /usr/bin/mongod --quiet --config /etc/mongod.conf

Apr 28 16:22:33 fhm85al4f0mh48nhcjoi systemd[1]: Started High-performance, schema-free document-oriented database.
Так же можно использовать модуль systemd
 ansible db -m systemd -a name=mongod - результат длинный, все не буду вписывать
  ansible  ansible-1 !8 ?1   ansible db -m systemd -a name=mongod                       ok  19:45:28
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, ...
А еще вот так можно
ansible db -m service -a name=mongod
Далее команда не выполнялась, так как на ВМ не установлен GIT. Усатновил. Вообще надо бы что бы автоматом, в идеале в образ запихнуть или терраформом запустить провиженер. ЧТо то я пропустил кажется!
 ansible  ansible-1 !8 ?1  ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
ppserver | CHANGED => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": null,
    "changed": true
}
Вторая команда
 ansible  ansible-1 !8 ?1  ansible app -m git -a \                                 ok  4s  19:57:39
 'repo=https://github.com/express42/reddit.git dest=/home/ubuntu/reddit'
ppserver | SUCCESS => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "changed": false,
    "remote_url_changed": false
}
Как мы видим, повторное выполнение этой команды проходит успешно,
только переменная changed будет false (что значит, что изменения не
произошли)
Плейбук. Звучит как порно.
Создали файл ansible/clone.yml
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
 ansible  ansible-1 !8 ?1  ansible-playbook clone.yml                                  ok  20:01:10

PLAY [Clone] ****************************************************************************************

TASK [Gathering Facts] ******************************************************************************
ok: [ppserver]

TASK [Clone repo] ***********************************************************************************
ok: [ppserver]

PLAY RECAP ******************************************************************************************
ppserver                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0
Напишем простой плейбук
Мы удалил то что загрузили и снова загрузили.
--------
HW8 ansible-2
--------
Создали плейбук ansible/reddit_app.yml
---
- name: Configure hosts & deploy application # <-- Словесное описание сценария (name)
  hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts)
  tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
    - name: Change mongo config file
      become: true # <-- Выполнить задание от root
      template:
        src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
        dest: /etc/mongod.conf # <-- Путь на удаленном хосте
        mode: 0644 # <-- Права на файл, которые нужно установить
      tags: db-tag # <-- Список тэгов для задачи
Создали шаблон конфига templates/mongod.conf.j2
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
Пробный прогон
 ansible  ansible-2 !8 ?2  ansible-playbook reddit-app.yml --check --limit db                                                                                                               2 err  22:23:28

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] *****************************************************************************************************************************************************************************
fatal: [dbserver]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: 'mongo_bind_ip' is undefined"}

PLAY RECAP **************************************************************************************************************************************************************************************************
dbserver                   : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
AnsibleUndefinedVariable - Ошибка❗ Переменная, которая
используется в шаблоне не определена
Задали переменную в плейбуке
  vars:
    mongo_bind_ip: 0.0.0.0
Снова прогон
 ansible  ansible-2 !8 ?2  ansible-playbook reddit-app.yml --check --limit db                                                                                                           2 err  5s  22:23:46

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] *****************************************************************************************************************************************************************************
changed: [dbserver]

PLAY RECAP **************************************************************************************************************************************************************************************************
dbserver                   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Handlers
Handlers похожи на таски, однако запускаются только по оповещению от
других задач.
Таск шлет оповещение handler-у в случае, когда он меняет свое
состояние. По этой причине handlers удобно использовать для перезапуска
сервисов.
Изменение конфигурационного файла MongoDВ требует от нас
перезапуска БД для применения конфигурации. Используем для этой
задачи handler.
Определим handler для рестарта БД и добавим вызов handler-а в
созданный нами таск.
Добавили к плейбуку
      notify: restart mongod
  handlers: # <-- Добавим блок handlers и задачу
    - name: restart mongod
      become: true
      service: name=mongod state=restarted
Прогнали
 ansible  ansible-2 !8 ?2  ansible-playbook reddit-app.yml --check --limit db                                                                                                                 INT  22:27:38

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] *****************************************************************************************************************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] ****************************************************************************************************************************************************************************
changed: [dbserver]

PLAY RECAP **************************************************************************************************************************************************************************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Запустили
 ansible  ansible-2 !8 ?2  ansible-playbook reddit-app.yml --limit db                                                                                                                      ok  8s  22:32:25

PLAY [Configure hosts & deploy application] *****************************************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] *****************************************************************************************************************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] ****************************************************************************************************************************************************************************
changed: [dbserver]

PLAY RECAP **************************************************************************************************************************************************************************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Настройка инстанса приложения
Добавили файл touch files/puma.service
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/appuser/db_config
User=appuser
WorkingDirectory=/home/appuser/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
Добавили задача и в плейбук, не забываем о хендлерах.
---
- name: Configure hosts & deploy application # <-- Словесное описание сценария (name)
  hosts: all # <-- Для каких хостов будут выполняться описанные ниже таски (hosts)
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks: # <-- Блок тасков (заданий), которые будут выполняться для данных хостов
    - name: Change mongo config file
      become: true # <-- Выполнить задание от root
      template:
        src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
        dest: /etc/mongod.conf # <-- Путь на удаленном хосте
        mode: 0644 # <-- Права на файл, которые нужно установить
      tags: db-tag # <-- Список тэгов для задачи
      notify: restart mongod

    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag

  handlers: # <-- Добавим блок handlers и задачу
    - name: restart mongod
      become: true
      service: name=mongod state=restarted
    - name: reload puma
      become: true
      systemd: name=puma state=restarted

Создали еще один шаблон
templates/db_config.j2
DATABASE_URL={{ db_host }}
Добавили переменную в плейбук db_host: 10.132.0.2 для видимости инстанса
Прогнали
 ansible  ansible-2 !9 ?3  ansible-playbook reddit-app.yml --check --limit app --tags app-tag

PLAY [Configure hosts & deploy application] *********************************************************

TASK [Gathering Facts] ******************************************************************************
ok: [appserver]

TASK [Add unit file for Puma] ***********************************************************************
ok: [appserver]

TASK [Add config for DB connection] *****************************************************************
ok: [appserver]

TASK [enable puma] **********************************************************************************
ok: [appserver]

PLAY RECAP ******************************************************************************************
appserver                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Деплой
Добавим еще несколько тасков в сценарий нашего плейбука. Используем модули git и bundle для клонирования последней версии кода нашего приложения и установки зависимых Ruby Gems через bundle .
Добавили в конфиг
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith # <-- Указываем нужную ветку
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle
      tags: deploy-tag
Проверили
 ansible  ansible-2 !9 ?3  ansible-playbook reddit-app.yml --limit app --tags deploy-tag

PLAY [Configure hosts & deploy application] *********************************************************

TASK [Gathering Facts] ******************************************************************************
ok: [appserver]

TASK [Fetch the latest version of application code] *************************************************
ok: [appserver]

TASK [Bundle install] *******************************************************************************
changed: [appserver]

PLAY RECAP ******************************************************************************************
appserver                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Приложение поднялось.
Разнесли БД и Приложение на разные деплои.
Пересоздали инстансы через терраформ.
 ansible  ansible-2 +13 !3 ?1  ansible-playbook reddit_app2.yml --tags db-tag

PLAY [Configure MongoDB] **************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [dbserver]

TASK [Change mongo config file] *******************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] ******************************************************
changed: [dbserver]

PLAY [Configure App] ******************************************************************

PLAY RECAP ****************************************************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
 ansible  ansible-2 +13 !3 ?1  ansible-playbook reddit_app2.yml --tags app-tag

PLAY [Configure MongoDB] **************************************************************

PLAY [Configure App] ******************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [appserver]

TASK [Add unit file for Puma] *********************************************************
changed: [appserver]

TASK [Add config for DB connection] ***************************************************
changed: [appserver]

TASK [enable puma] ********************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] *********************************************************
changed: [appserver]

PLAY RECAP ****************************************************************************
appserver                  : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Добавили деплой
Так же добавили установку гита
    - name: Install git
      apt:
        name: git
        state: present
        update_cache: yes
 ansible  ansible-2 +13 !3 ?1  ansible-playbook reddit_app2.yml --tags deploy-tag

PLAY [Configure MongoDB] **************************************************************

PLAY [Configure App] ******************************************************************

PLAY [Deploy App] *********************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [appserver]

TASK [Install git] ********************************************************************
ok: [appserver]

TASK [Fetch the latest version of application code] ***********************************
ok: [appserver]

TASK [bundle install] *****************************************************************
ok: [appserver]

PLAY RECAP ****************************************************************************
appserver                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
Приложение поднялось на верх
Несколько плейбуков
Разнесли деплой на разные ямл.
Все сценарии обозначили в site.yml
запустились и ОК
 ansible  ansible-2 +13 !3 ?1   ansible-playbook site.yml               INT  20:20:42

PLAY [Configure mongod] ***************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [dbserver]

TASK [Change mongo config file] *******************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] ******************************************************
changed: [dbserver]

PLAY [Configure app] ******************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [appserver]

TASK [Add unit file for Puma] *********************************************************
changed: [appserver]

TASK [Add config for DB connection] ***************************************************
changed: [appserver]

TASK [enable puma] ********************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] *********************************************************
changed: [appserver]

PLAY [Deploy App] *********************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [appserver]

TASK [insatall git] *******************************************************************
changed: [appserver]

TASK [Fetch the latest version of application code] ***********************************
changed: [appserver]

TASK [bundle install] *****************************************************************
changed: [appserver]

RUNNING HANDLER [restart puma] ********************************************************
changed: [appserver]

PLAY RECAP ****************************************************************************
appserver                  : ok=10   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0
