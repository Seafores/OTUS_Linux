### Цель: Управление автозагрузкой сервисов происходит через systemd. Вместо cron'а тоже используется systemd. И много других возможностей. В ДЗ нужно написать свой systemd-unit.
### 1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig
### 2. Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться.
### 3. Дополнить юнит-файл apache httpd возможностьб запустить несколько инстансов сервера с разными конфигами
### 4*. Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл
### Задание необходимо сделать с использованием Vagrantfile и proviosioner shell (или ansible, на Ваше усмотрение) 

---

#### Часть первая, мониторить будем /var/log/messages
```
[root@hw7 vagrant]# nano /etc/sysconfig/mainlog
[root@hw7 vagrant]# cat /etc/sysconfig/mainlog
WORD="OpenSSH"
LOG="/var/log/messages"
```

##### Создаем скрипт для проверки

```
[root@hw7 vagrant]# nano /opt/checklog.sh
[root@hw7 vagrant]# cat /opt/checklog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```

##### Создаем два юнит файла. Первый описывает сервис, второй его запускает раз в 30 секунд.
```
[root@hw7 vagrant]# cd /etc/systemd/system/
[root@hw7 system]# nano mainlog.service
[root@hw7 system]# cat mainlog.service
[Unit]
Description=Check Word

[Service]
EnvironmentFile=/etc/sysconfig/mainlog
ExecStart=/opt/checklog.sh $WORD $LOG
```

```
[root@hw7 system]# nano mainlog.timer
[root@hw7 system]# cat mainlog.timer
[Unit]
Description=Timer
[Timer]
OnUnitActiveSec=30s
Unit=mainlog.service
[Install]
WantedBy=timers.target
```

##### Обновляем список юнитов:
```
[root@hw7 system]# systemctl daemon-reload
```

##### Устанавливаем наш сервис
```
[root@hw7 vagrant]# systemctl enable mainlog.service
```

##### Устанавливаем на него таймер
```
[root@hw7 vagrant]# systemctl enable mainlog.timer
Created symlink from /etc/systemd/system/timers.target.wants/mainlog.timer to /etc/systemd/system/mainlog.timer.
```
##### Запускаем таймер
```
[root@hw7 system]# systemctl start mainlog.timer
```

##### Добавляем события в /var/log/messages
```
[root@hw7 system]# systemctl restart sshd
```

##### Проверяем
```
[root@hw7 system]# systemctl list-timers --all
NEXT                         LEFT     LAST                         PASSED    UNIT                         ACTIVATES
Sat 2019-08-31 14:53:40 UTC  18s left Sat 2019-08-31 14:53:10 UTC  11s ago   mainlog.timer                mainlog.service
Sun 2019-09-01 14:40:06 UTC  23h left Sat 2019-08-31 14:40:06 UTC  13min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
n/a                          n/a      n/a                          n/a       systemd-readahead-done.timer systemd-readahead-done.service
```

```
[root@hw7 system]# systemctl status mainlog -l
● mainlog.service - Check Word
   Loaded: loaded (/etc/systemd/system/mainlog.service; static; vendor preset: disabled)
   Active: inactive (dead) since Sat 2019-08-31 14:56:56 UTC; 21s ago
  Process: 3447 ExecStart=/opt/checklog.sh $WORD $LOG (code=exited, status=0/SUCCESS)
 Main PID: 3447 (code=exited, status=0/SUCCESS)

Aug 31 14:56:56 hw7.1.otus.ru systemd[1]: Started Check Word.
```

```
[root@hw7 system]# cat /var/log/messages

Aug 31 14:54:00 hw7 systemd: Stopping OpenSSH server daemon...
Aug 31 14:54:00 hw7 systemd: Stopped OpenSSH server daemon.
Aug 31 14:54:00 hw7 systemd: Starting OpenSSH server daemon...
Aug 31 14:54:00 hw7 systemd: Started OpenSSH server daemon.
Aug 31 14:55:06 hw7 systemd: Started Check Word.
Aug 31 14:55:06 hw7 root: Sat Aug 31 14:55:06 UTC 2019: I found word, Master!
Aug 31 14:56:06 hw7 systemd: Started Check Word.
Aug 31 14:56:06 hw7 root: Sat Aug 31 14:56:06 UTC 2019: I found word, Master!
```

---

#### Приступаем ко второй части ДЗ. Устанавливаем необходимые пакеты.
```
[root@hw7 system]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.sale-dedic.com
 * extras: mirror.sale-dedic.com
 * updates: mirror.linux-ia64.org
Resolving Dependencies
--> Running transaction check
---> Package epel-release.noarch 0:7-11 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

============================================================================================================================================================================
 Package                                       Arch                                    Version                                Repository                               Size
============================================================================================================================================================================
Installing:
 epel-release                                  noarch                                  7-11                                   extras                                   15 k

Transaction Summary
============================================================================================================================================================================
Install  1 Package

Total download size: 15 k
Installed size: 24 k
Downloading packages:
epel-release-7-11.noarch.rpm                                                                                                                         |  15 kB  00:00:00
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : epel-release-7-11.noarch                                                                                                                                 1/1
  Verifying  : epel-release-7-11.noarch                                                                                                                                 1/1

Installed:
  epel-release.noarch 0:7-11

Complete!
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                                                                                 |  29 kB  00:00:00
 * base: mirror.sale-dedic.com
 * epel: mirror.linux-ia64.org
 * extras: mirror.sale-dedic.com
 * updates: mirror.linux-ia64.org
epel                                                                                                                                                 | 5.3 kB  00:00:00
(1/3): epel/x86_64/group_gz                                                                                                                          |  88 kB  00:00:00
(2/3): epel/x86_64/updateinfo                                                                                                                        | 1.0 MB  00:00:01
(3/3): epel/x86_64/primary_db                                                                                                                        | 6.8 MB  00:00:06
Resolving Dependencies
--> Running transaction check
---> Package httpd.x86_64 0:2.4.6-89.el7.centos.1 will be installed
--> Processing Dependency: httpd-tools = 2.4.6-89.el7.centos.1 for package: httpd-2.4.6-89.el7.centos.1.x86_64
--> Processing Dependency: /etc/mime.types for package: httpd-2.4.6-89.el7.centos.1.x86_64
--> Processing Dependency: libaprutil-1.so.0()(64bit) for package: httpd-2.4.6-89.el7.centos.1.x86_64
--> Processing Dependency: libapr-1.so.0()(64bit) for package: httpd-2.4.6-89.el7.centos.1.x86_64
---> Package mod_fcgid.x86_64 0:2.3.9-4.el7_4.1 will be installed
---> Package php.x86_64 0:5.4.16-46.el7 will be installed
--> Processing Dependency: php-common(x86-64) = 5.4.16-46.el7 for package: php-5.4.16-46.el7.x86_64
---> Package php-cli.x86_64 0:5.4.16-46.el7 will be installed
---> Package spawn-fcgi.x86_64 0:1.6.3-5.el7 will be installed
--> Running transaction check
---> Package apr.x86_64 0:1.4.8-3.el7_4.1 will be installed
---> Package apr-util.x86_64 0:1.5.2-6.el7 will be installed
---> Package httpd-tools.x86_64 0:2.4.6-89.el7.centos.1 will be installed
---> Package mailcap.noarch 0:2.1.41-2.el7 will be installed
---> Package php-common.x86_64 0:5.4.16-46.el7 will be installed
--> Processing Dependency: libzip.so.2()(64bit) for package: php-common-5.4.16-46.el7.x86_64
--> Running transaction check
---> Package libzip.x86_64 0:0.10.1-8.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

============================================================================================================================================================================
 Package                                  Arch                                Version                                            Repository                            Size
============================================================================================================================================================================
Installing:
 httpd                                    x86_64                              2.4.6-89.el7.centos.1                              updates                              2.7 M
 mod_fcgid                                x86_64                              2.3.9-4.el7_4.1                                    base                                  79 k
 php                                      x86_64                              5.4.16-46.el7                                      base                                 1.4 M
 php-cli                                  x86_64                              5.4.16-46.el7                                      base                                 2.7 M
 spawn-fcgi                               x86_64                              1.6.3-5.el7                                        epel                                  18 k
Installing for dependencies:
 apr                                      x86_64                              1.4.8-3.el7_4.1                                    base                                 103 k
 apr-util                                 x86_64                              1.5.2-6.el7                                        base                                  92 k
 httpd-tools                              x86_64                              2.4.6-89.el7.centos.1                              updates                               91 k
 libzip                                   x86_64                              0.10.1-8.el7                                       base                                  48 k
 mailcap                                  noarch                              2.1.41-2.el7                                       base                                  31 k
 php-common                               x86_64                              5.4.16-46.el7                                      base                                 565 k

Transaction Summary
============================================================================================================================================================================
Install  5 Packages (+6 Dependent packages)

Total download size: 7.8 M
Installed size: 27 M
Downloading packages:
(1/11): apr-1.4.8-3.el7_4.1.x86_64.rpm                                                                                                               | 103 kB  00:00:00
(2/11): mailcap-2.1.41-2.el7.noarch.rpm                                                                                                              |  31 kB  00:00:00
(3/11): mod_fcgid-2.3.9-4.el7_4.1.x86_64.rpm                                                                                                         |  79 kB  00:00:00
(4/11): libzip-0.10.1-8.el7.x86_64.rpm                                                                                                               |  48 kB  00:00:00
(5/11): apr-util-1.5.2-6.el7.x86_64.rpm                                                                                                              |  92 kB  00:00:00
(6/11): httpd-tools-2.4.6-89.el7.centos.1.x86_64.rpm                                                                                                 |  91 kB  00:00:00
(7/11): php-common-5.4.16-46.el7.x86_64.rpm                                                                                                          | 565 kB  00:00:00
(8/11): php-5.4.16-46.el7.x86_64.rpm                                                                                                                 | 1.4 MB  00:00:00
(9/11): httpd-2.4.6-89.el7.centos.1.x86_64.rpm                                                                                                       | 2.7 MB  00:00:00
(10/11): php-cli-5.4.16-46.el7.x86_64.rpm                                                                                                            | 2.7 MB  00:00:00
warning: /var/cache/yum/x86_64/7/epel/packages/spawn-fcgi-1.6.3-5.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID 352c64e5: NOKEY=-] 6.8 MB/s | 7.8 MB  00:00:00 ETA
Public key for spawn-fcgi-1.6.3-5.el7.x86_64.rpm is not installed
(11/11): spawn-fcgi-1.6.3-5.el7.x86_64.rpm                                                                                                           |  18 kB  00:00:00
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                       5.2 MB/s | 7.8 MB  00:00:01
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Importing GPG key 0x352C64E5:
 Userid     : "Fedora EPEL (7) <epel@fedoraproject.org>"
 Fingerprint: 91e9 7d7c 4a5e 96f1 7f3e 888f 6a2f aea2 352c 64e5
 Package    : epel-release-7-11.noarch (@extras)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : apr-1.4.8-3.el7_4.1.x86_64                                                                                                                              1/11
  Installing : apr-util-1.5.2-6.el7.x86_64                                                                                                                             2/11
  Installing : httpd-tools-2.4.6-89.el7.centos.1.x86_64                                                                                                                3/11
  Installing : libzip-0.10.1-8.el7.x86_64                                                                                                                              4/11
  Installing : php-common-5.4.16-46.el7.x86_64                                                                                                                         5/11
  Installing : php-cli-5.4.16-46.el7.x86_64                                                                                                                            6/11
  Installing : mailcap-2.1.41-2.el7.noarch                                                                                                                             7/11
  Installing : httpd-2.4.6-89.el7.centos.1.x86_64                                                                                                                      8/11
  Installing : mod_fcgid-2.3.9-4.el7_4.1.x86_64                                                                                                                        9/11
  Installing : php-5.4.16-46.el7.x86_64                                                                                                                               10/11
  Installing : spawn-fcgi-1.6.3-5.el7.x86_64                                                                                                                          11/11
  Verifying  : mod_fcgid-2.3.9-4.el7_4.1.x86_64                                                                                                                        1/11
  Verifying  : httpd-2.4.6-89.el7.centos.1.x86_64                                                                                                                      2/11
  Verifying  : httpd-tools-2.4.6-89.el7.centos.1.x86_64                                                                                                                3/11
  Verifying  : spawn-fcgi-1.6.3-5.el7.x86_64                                                                                                                           4/11
  Verifying  : mailcap-2.1.41-2.el7.noarch                                                                                                                             5/11
  Verifying  : apr-util-1.5.2-6.el7.x86_64                                                                                                                             6/11
  Verifying  : php-cli-5.4.16-46.el7.x86_64                                                                                                                            7/11
  Verifying  : libzip-0.10.1-8.el7.x86_64                                                                                                                              8/11
  Verifying  : php-5.4.16-46.el7.x86_64                                                                                                                                9/11
  Verifying  : php-common-5.4.16-46.el7.x86_64                                                                                                                        10/11
  Verifying  : apr-1.4.8-3.el7_4.1.x86_64                                                                                                                             11/11

Installed:
  httpd.x86_64 0:2.4.6-89.el7.centos.1  mod_fcgid.x86_64 0:2.3.9-4.el7_4.1  php.x86_64 0:5.4.16-46.el7  php-cli.x86_64 0:5.4.16-46.el7  spawn-fcgi.x86_64 0:1.6.3-5.el7

Dependency Installed:
  apr.x86_64 0:1.4.8-3.el7_4.1       apr-util.x86_64 0:1.5.2-6.el7  httpd-tools.x86_64 0:2.4.6-89.el7.centos.1  libzip.x86_64 0:0.10.1-8.el7  mailcap.noarch 0:2.1.41-2.el7
  php-common.x86_64 0:5.4.16-46.el7

Complete!
```

##### Раскоментируем последние строки в файле spawn-fcgi
```
[root@hw7 system]# nano /etc/sysconfig/spawn-fcgi
[root@hw7 system]# cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```

##### Создаем Unit файл
```
[root@hw7 system]# nano spawn-fcgi.service
[root@hw7 system]# cat spawn-fcgi.service
[Unit]
Description=Spawn FastCGI
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```
##### Обновляем список юнитов:
```
[root@hw7 system]# systemctl daemon-reload
```

##### Устанавливаем и запускаем наш сервис
```
[root@hw7 system]# systemctl enable spawn-fcgi.service
Created symlink from /etc/systemd/system/multi-user.target.wants/spawn-fcgi.service to /etc/systemd/system/spawn-fcgi.service.
```

##### Запускаем и проверяем
```
[root@hw7 system]# systemctl start spawn-fcgi
[root@hw7 system]#  systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn FastCGI
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2019-08-31 15:14:52 UTC; 8s ago
 Main PID: 3841 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─3841 /usr/bin/php-cgi
           ├─3842 /usr/bin/php-cgi
           ├─3843 /usr/bin/php-cgi
           ├─3844 /usr/bin/php-cgi
           ├─3845 /usr/bin/php-cgi
           ├─3846 /usr/bin/php-cgi
           ├─3847 /usr/bin/php-cgi
           ├─3848 /usr/bin/php-cgi
           ├─3849 /usr/bin/php-cgi
           ├─3850 /usr/bin/php-cgi
           ├─3851 /usr/bin/php-cgi
           ├─3852 /usr/bin/php-cgi
           ├─3853 /usr/bin/php-cgi
           ├─3854 /usr/bin/php-cgi
           ├─3855 /usr/bin/php-cgi
           ├─3856 /usr/bin/php-cgi
           ├─3857 /usr/bin/php-cgi
           ├─3858 /usr/bin/php-cgi
           ├─3859 /usr/bin/php-cgi
           ├─3860 /usr/bin/php-cgi
           ├─3861 /usr/bin/php-cgi
           ├─3862 /usr/bin/php-cgi
           ├─3863 /usr/bin/php-cgi
           ├─3864 /usr/bin/php-cgi
           ├─3865 /usr/bin/php-cgi
           ├─3866 /usr/bin/php-cgi
           ├─3867 /usr/bin/php-cgi
           ├─3868 /usr/bin/php-cgi
           ├─3869 /usr/bin/php-cgi
           ├─3870 /usr/bin/php-cgi
           ├─3871 /usr/bin/php-cgi
           ├─3872 /usr/bin/php-cgi
           └─3873 /usr/bin/php-cgi

Aug 31 15:14:52 hw7.1.otus.ru systemd[1]: Started Spawn FastCGI.
```

---

#### Приступем к третьей части ДЗ. Делаем Unit файл для создания дублирующего процесса.
```
[root@hw7 vagrant]# nano /etc/systemd/system/httpd@.service
[root@hw7 vagrant]# cat /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

##### Создаем файлы конфигурации
```
[root@hw7 vagrant]# nano /etc/sysconfig/httpd-first
[root@hw7 vagrant]# cat /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
```

```
[root@hw7 vagrant]# nano /etc/sysconfig/httpd-second
[root@hw7 vagrant]# cat /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```

##### Настраиваем индивидуальные httpd.conf (отличаются PidFile и Listen)
```
[root@hw7 vagrant]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
[root@hw7 vagrant]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf

[root@hw7 vagrant]# cat /etc/httpd/conf/first.conf
...
ServerRoot "/etc/httpd"
PidFile /var/run/httpd-first.pid
Listen 80
...

[root@hw7 vagrant]# cat /etc/httpd/conf/second.conf
...
ServerRoot "/etc/httpd"
PidFile /var/run/httpd-second.pid
Listen 8080
...
```

##### Запускаем шарманку
```
[root@hw7 vagrant]# systemctl start httpd@first
[root@hw7 vagrant]# systemctl start httpd@second
```


##### Проверяем
```
[root@hw7 vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=1421,fd=4),("httpd",pid=1420,fd=4),("httpd",pid=1419,fd=4),("httpd",pid=1418,fd=4),("httpd",pid=1417,fd=4),("httpd",pid=1416,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=1409,fd=4),("httpd",pid=1408,fd=4),("httpd",pid=1407,fd=4),("httpd",pid=1406,fd=4),("httpd",pid=1405,fd=4),("httpd",pid=1404,fd=4))
```
