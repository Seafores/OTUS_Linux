# Домашнее задание 10 (OTUS Linux 2019 - 07)

### 1. Запретить всем пользователям, кроме группы admin логин в выходные(суббота и воскресенье), без учета праздников
### 2. Дать конкретному пользователю права рута 

---

#### Прикладываю [Vagrantfile](Vagrantfile) с встроенным bash скриптом, делал методичку по нему.
#### Обновляем систему и устанавливаем дополнительные приложения
```
yum update -y
yum install -y nano mc
```
#### Устанавливаю Русскую локализацию
```
localectl set-locale LANG=ru_RU.UTF-8
```
#### Создаю пользователя testuser c паролем Otus2019
```
adduser testuser -c "Test User" -d /home/testuser -p "$(python -c 'import crypt; print(crypt.crypt("Otus2019", crypt.mksalt(crypt.METHOD_SHA512)))')"
```
#### Проверяем
```
[root@hw10 vagrant]# cat /etc/passwd | grep test
testuser:x:1001:1001:Test User:/home/testuser:/bin/bash
```
#### Разрешаем вход по shh по паролю
```
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
```
#### Проверяем
```
[root@hw10 vagrant]# cat /etc/ssh/sshd_config | grep PasswordAuthentication
#PasswordAuthentication yes
PasswordAuthentication yes
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication, then enable this but set PasswordAuthentication
```
#### Установил сервер времени и установил актуальное время с часовым поясом.
```
yum install ntpdate -y
ntpdate -s pool.ntp.org
timedatectl set-timezone Asia/Yekaterinburg
```
#### Т.к. доступ по заданию разрешен только в будни, предполагаем что по заданию данная ПЭВМ используется только в рабочее время. Поэтому прописываю доступ только с понедельника по пятницу, с 8:00 до 17:00 (для примера).
```
echo '* ; * ; !root ; MoTuWeThFr0800-1700' >> /etc/security/time.conf
```
#### Не был уверен, влияет очередность в правильности работы, поэтому привел к виду, который нашел в интернете (очередность auth, account и т.д.)
```
echo "" > /etc/pam.d/sshd
echo "auth       required     pam_sepermit.so" >> /etc/pam.d/sshd
echo "auth       substack     password-auth" >> /etc/pam.d/sshd
echo "auth       include      postlogin" >> /etc/pam.d/sshd
echo "-auth      optional     pam_reauthorize.so prepare" >> /etc/pam.d/sshd
echo "account    required     pam_nologin.so" >> /etc/pam.d/sshd
echo "account    include      password-auth" >> /etc/pam.d/sshd
echo "account    required     pam_time.so" >> /etc/pam.d/sshd
echo "password   include      password-auth" >> /etc/pam.d/sshd
echo "session    required     pam_selinux.so close" >> /etc/pam.d/sshd
echo "session    required     pam_loginuid.so" >> /etc/pam.d/sshd
echo "session    required     pam_selinux.so open env_params" >> /etc/pam.d/sshd
echo "session    required     pam_namespace.so" >> /etc/pam.d/sshd
echo "session    optional     pam_keyinit.so force revoke" >> /etc/pam.d/sshd
echo "session    include      password-auth" >> /etc/pam.d/sshd
echo "session    include      postlogin" >> /etc/pam.d/sshd
echo "-session   optional     pam_reauthorize.so prepare" >> /etc/pam.d/sshd
```
#### Перезагружаюсь
```
reboot
```
#### Проверяем.. (на момент проверки был понедельник после 17-00, нерабочее время).
```
F:\Vagrant>Vagrant ssh
Last login: Mon Sep 30 18:35:26 2019 from 10.0.2.2
[vagrant@hw10 ~]$ su testuser
Password:
[testuser@hw10 vagrant]$ date
Пн сен 30 18:48:30 +05 2019
[testuser@hw10 vagrant]$
```

#### Как видим, в пользователя testuser заходит...
## Ч.Я.Д.Н.Т.? 

---

### Задача 2
```
usermod -aG wheel test_user
```
#### В практике так же использовал редактирование файла /etc/sudoers (можно настроить доступ после ввода пароля и без ввода) и добавление в группу sudo (debian):
```
adduser testuser sudo
```
