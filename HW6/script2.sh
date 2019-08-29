#!/usr/bin/env bash

# Расширеное описание тут
# https://github.com/Seafores/OTUS_Linux/tree/master/HW6

yum update -y
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
wget -P /home/vagrant https://www.nano-editor.org/dist/v4/nano-4.4.tar.xz
tar -xf /home/vagrant/nano-4.4.tar.xz
sed -i '/.*fr.*man.*/d' /home/vagrant/nano-4.4/nano.spec
yum-builddep /home/vagrant/nano-4.4/nano.spec -y
wget -P /root/rpmbuild/SOURCES https://www.nano-editor.org/dist/v4/nano-4.4.tar.gz
rpmbuild -bb /home/vagrant/nano-4.4/nano.spec
mkdir -p /var/www/html/repo/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
cp /root/rpmbuild/RPMS/x86_64/nano-4.4-1.x86_64.rpm /var/www/html/repo/nano-4.4-1.x86_64.rpm
chown -R root.root /var/www/html/repo
createrepo /var/www/html/repo
chmod -R o-w+r /var/www/html/repo
yum install httpd -y
service httpd start

cat >> /etc/yum.repos.d/HW6Repo.repo << EOF
[HW6Repo]
# Имя репозитория
name=HW6 Repo
# Путь к web репозиторию
baseurl=file:///var/www/html/repo
# Репозиторий используется
enabled=1
# Отключаем проверку ключом
gpgcheck=0
EOF

# После заходим в систему и пишем yum update и yum install nano
