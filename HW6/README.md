#### Размещаем свой RPM в своем репозитории
#### Цель: Часто в задачи администратора входит не только установка пакетов, но и сборка и поддержка собственного репозитория. Этим и займемся в ДЗ.
#### 1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
#### 2) создать свой репо и разместить там свой RPM
#### реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо
#### * реализовать дополнительно пакет через docker
#### Критерии оценки: 5 - есть репо и рпм
#### +1 - сделан еще и докер образ

###### Преподавателю сразу говорю, докер не делал и делать не буду, это животное мне сломало виртуалки на VirtualBox (Не знаю как, но после него ничего не запускалось (зависало на подгрузке cpu и timer), пришлось преустанавливать Windows :)

---

### Первую часть работы выполняю на виртуальной машине hw6.2.otus.ru
```
[root@hw6 vagrant]# hostname
hw6.2.otus.ru
```

###### Установим необходимые утилиты для выполнения данного ДЗ
```
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
```

###### Собирать rpm пакет буду для обновления программы nano, смотрим текущую версию
```
[root@hw6 openssl-1.1.1c]# nano -V
GNU nano version 2.3.1 (compiled 04:47:52, Jun 10 2014)
(C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 Free Software Foundation, Inc.
Email: nano@nano-editor.org Web: http://www.nano-editor.org/
Compiled options: --enable-color --enable-extra --enable-multibuffer --enable-nanorc --enable-utf8
```
```
[root@hw6 openssl-1.1.1c]# yum install nano     
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * extras: ftp.nsc.ru
 * updates: mirror.corbina.net
Package nano-2.3.1-10.el7.x86_64 already installed and latest version
Nothing to do
```

###### Скачиваем последнюю версия с офф. сайта
```
wget https://www.nano-editor.org/dist/v4/nano-4.4.tar.xz
```

###### Распаковываем
```
[root@hw6 vagrant]# tar -xf nano-4.4.tar.xz
[root@hw6 vagrant]# cd nano-4.4/
```

###### Заранее поставим все зависимости чтобы в процессе сборки не было ошибок
```
[root@hw6 nano-4.4]# yum-builddep nano.spec 

* * *
Магия
* * * 

Installed:
autoconf.noarch 0:2.69-11.el7 automake.noarch 0:1.13.4-3.el7 gettext-devel.x86_64 0:0.19.8.1-2.el7 ncurses-devel.x86_64 0:5.9-14.20130511.el7_4 texinfo.x86_64 0:5.1-5.el7

Dependency Installed: 
gettext-common-devel.noarch 0:0.19.8.1-2.el7 git.x86_64 0:1.8.3.1-20.el7 perl-Data-Dumper.x86_64 0:2.145-3.el7perl-Error.noarch 1:0.17020-2.el7 perl-Git.noarch 0:1.8.3.1-20.el7
perl-TermReadKey.x86_64 0:2.30-20.el7perl-Test-Harness.noarch 0:3.28-3.el7 perl-Text-Unidecode.noarch 0:0.04-20.el7 perl-libintl.x86_64 0:1.20-12.el7 

Complete!
```

##### Удалил строку "%{_mandir}/fr/man*/*" из spec файла, т.к. при сборке говорит что файлы отсутствуют (man файлы), собираем пакет
```
[root@hw6 nano-4.4]# rpmbuild -bb nano.spec
error: File /root/rpmbuild/SOURCES/nano-4.4.tar.gz: No such file or directory
cd /root/rpmbuild/SOURCES/
wget https://www.nano-editor.org/dist/v4/nano-4.4.tar.gz
rpmbuild -bb /home/vagrant/nano-4.4/nano.spec
```                                                                                       

```
***
Магия
***
...
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.vfzvLf
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nano-4.4
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nano-4.4-1.x86_64
+ exit 0
```

##### Проверяю собралось ли
```
[root@hw6 vagrant]# ll /root/rpmbuild/RPMS/x86_64
total 1128
-rw-r--r--. 1 root root 650148 Aug 27 11:35 nano-4.4-1.x86_64.rpm                                                 
-rw-r--r--. 1 root root 500756 Aug 27 11:35 nano-debuginfo-4.4-1.x86_64.rpm
```

---

##### Создаем папки для репозитоия
```
mkdir -p /var/www/html/repo/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
```

##### Копируем новый rpm пакет
```
cp /root/rpmbuild/RPMS/x86_64/nano-4.4-1.x86_64.rpm /var/www/html/repo/nano-4.4-1.x86_64.rpm
```

##### Назначаем права
```
chown -R root.root /var/www/html/repo
```

##### Устанавливаем createrepo
```
[root@hw6 repository]# createrepo /var/www/html/repo
Spawning worker 0 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```

##### Видим что там отобразился 1 пакет, прописываем права доступа на папку
```
chmod -R o-w+r /var/www/html/repo
```

##### Устанавливаем httpd
```
yum install httpd -y
```

##### Запускаем веб-сервер
```
[root@hw6 vagrant]# service httpd start
Redirecting to /bin/systemctl start httpd.service
```

---

### Переходим на другую виртуальную машину
```
[root@hw6 vagrant]# hostname
hw6.1.otus.ru
```

##### Добавляем на второй машине ссылку на репозиторий
```
nano /etc/yum.repos.d/HW6RepoS.repo
[HW6RepoS]
# Имя репозитория
name=HW6 Repos
# Путь к web репозиторию
baseurl=http://10.10.20.52/repo
# Репозиторий используется
enabled=1
# Отключаем проверку ключом
gpgcheck=0
```

##### Проверяю текущую версию nano
```
[root@hw6 vagrant]# nano -V
 GNU nano version 2.3.1 (compiled 04:47:52, Jun 10 2014)
 (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007,
 2008, 2009 Free Software Foundation, Inc.
 Email: nano@nano-editor.org    Web: http://www.nano-editor.org/
 Compiled options: --enable-color --enable-extra --enable-multibuffer --enable-nanorc --enable-utf8
```

##### Обновляем списки репозиториев
```
[root@hw6 yum.repos.d]# yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.corbina.net
 * extras: mirror.yandex.ru
 * updates: mirror.corbina.net
repo id			repo name		status
HW6RepoS		HW6 Repos		1
base/7/x86_64		CentOS-7 - Base		10,019
extras/7/x86_64		CentOS-7 - Extras	435
updates/7/x86_64	CentOS-7 - Updates	2,500
repolist: 12,955
```
```
[root@hw6 yum.repos.d]# yum list nano
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.corbina.net
 * extras: mirror.yandex.ru
 * updates: mirror.corbina.net
Installed Packages
nano.x86_64               2.3.1-10.el7               @base
Available Packages
nano.x86_64               4.4-1                      HW6RepoS
```

##### yum наблюдает nano в двух репозиториях, обновляем ПО
```
[root@hw6 yum.repos.d]# yum update
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.corbina.net
 * extras: mirror.yandex.ru
 * updates: mirror.corbina.net
Resolving Dependencies
--> Running transaction check
---> Package nano.x86_64 0:2.3.1-10.el7 will be updated
---> Package nano.x86_64 0:4.4-1 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

============================================================= Package    Arch         Version        Repository      Size
=============================================================Updating:
 nano       x86_64       4.4-1          HW6RepoS       635 k

Transaction Summary
=============================================================Upgrade  1 Package

Total download size: 635 k
Is this ok [y/d/N]: y
Downloading packages:
No Presto metadata available for HW6RepoS
nano-4.4-1.x86_64.rpm                                                                                           | 635 kB  00:00:00
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : nano-4.4-1.x86_64                                                                                                   1/2
  Cleanup    : nano-2.3.1-10.el7.x86_64                                                                                            2/2
  Verifying  : nano-4.4-1.x86_64                                                                                                   1/2
  Verifying  : nano-2.3.1-10.el7.x86_64                                                                                            2/2

Updated:
  nano.x86_64 0:4.4-1

Complete!
```

```
[root@hw6 yum.repos.d]# nano -V
 GNU nano, version 4.4
 (C) 1999-2011, 2013-2019 Free Software Foundation, Inc.
 (C) 2014-2019 the contributors to nano
 Email: nano@nano-editor.org    Web: https://nano-editor.org/
 Compiled options: --disable-libmagic --enable-utf8
```

### На этом моменте при выполнении ДЗ был собран rpm пакет, создан и расшарен по http репозиторий и через него был обновлен дистрибутив nano
