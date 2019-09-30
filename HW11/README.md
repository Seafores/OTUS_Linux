# Домашнее задание 11 (OTUS Linux 2019 - 07)
### Настройка мониторинга
### Настроить дашборд с 4-мя графиками
### 1) память
### 2) процессор
### 3) диск
### 4) сеть
### 
### настроить на одной из систем
### - zabbix (использовать screen (комплексный экран))
### - prometheus - grafana
### 
### * использование систем примеры которых не рассматривались на занятии
### - список возможных систем был приведен в презентации
### 
### в качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего
### Критерии оценки: 5 - основное задание
### 6 - задание со зведочкой 

---

#### Статьи на будущее:
#### https://www.zabbix.com/documentation/4.0/ru/manual/installation/install_from_packages/rhel_centos
#### https://wiki.merionet.ru/servernye-resheniya/7/ustanovka-mysql-server-na-centos-7/
#### https://serveradmin.ru/ustanovka-i-nastroyka-zabbix-4-0/
#### https://www.itzgeek.com/how-tos/linux/centos-how-tos/how-to-install-zabbix-server-3-2-on-centos-7-ubuntu-16-04-debian-8.html

---

#### Устанавливаем php плюшки
```
yum -y install php php-cli php-common php-devel php-pear php-gd php-mbstring php-mysql php-xml php-bcmath
```
#### Активируем репозиторий опциональных rpm пакетов
```
yum-config-manager --enable rhel-7-server-optional-rpms
```
#### Подключаем репозиторий
```
rpm -Uvh https://repo.zabbix.com/zabbix/4.3/rhel/7/x86_64/zabbix-release-4.3-3.el7.noarch.rpm
```
#### Устанавливаем Zabbix
```
yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent
```
#### Настраил свою часовю зону в конфиге
```
[root@hw11 vagrant]# cat /etc/httpd/conf.d/zabbix.conf | grep zone
        php_value date.timezone Asia/Yekaterinburg
```
#### Устанавливаем БД
```
yum install -y mariadb-server mariadb
```
#### Запускаем БД
```
systemctl start mariadb
```
#### Сбрасываю пароль на сервер БД
```
mysql_secure_installation
```
#### Пароль 4Fdz;i?Y!MhC, остальные опции -Y
#### Создаем базу для заббикса и пользователя, выдаем права
```
mysql -u root -p

> create database zabbixdb character set utf8 collate utf8_bin;
> grant all privileges on zabbixdb.* to zabbixuser@localhost identified by 'password';
> quit;
```
#### Bмпортируйте исходную схему
```
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbixuser -p zabbixdb

```
#### Прописываем настройки базы в конфиге
```
/etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbixdb
DBUser=zabbixuser
DBPassword=password
```
#### Перезапускам сервисы и добавляем их в автозагрузку
```
systemctl restart zabbix-server zabbix-agent httpd
systemctl enable zabbix-server zabbix-agent httpd mariadb
```
#### Заходим на веб интернфейс и настраиваем
### http://localhost:8080/zabbix/setup.php
### 
## Далее донастроил стандартный шаблон и сделал [дашборд](Zabbix.jpg).








