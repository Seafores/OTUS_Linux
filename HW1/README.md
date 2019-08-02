# Домашнее задание 1 (OTUS Linux 2019 - 07)
## По просьбе преподавателя описываю текстом что я сделал (было в конце лекции)

```
cd "C:\HashiCorp\1.Kernel"
```

###### Положил файл из материалов в папку 1.Kernel, в нём поправил имя машины и увеличил объем RAM до 2ГБ.
```
vagrant up
vagrant status
vagrant ssh

sudo su
yum update
```

###### Устанавливаю ПО для дальшейшей работы (понадобится для компиляции ядра)
```
yum install nano mc bc gcc wget
yum install ncurses-devel make bison flex elfutils-libelf-devel openssl-devel grub2

reboot
```

```
sudo su
[root@KernelVM vagrant]# uname -r
3.10.0-957.21.3.el7.x86_64

[root@KernelVM vagrant]# rpm -q kernel
kernel-3.10.0-957.12.2.el7.x86_64
kernel-3.10.0-957.21.3.el7.x86_64
```

###### Удаляю старые ядра
```
yum remove kernel

shutdown -h now
```

###### На всякий случай делаю снапшот, чтобы мог начать заного
```
vagrant snapshot save KernelVM
C:\HashiCorp\1.Kernel>vagrant snapshot list
==> KernelVM:
KernelVM
```

###### Скачиваю mainline ядро (последнее на 27.07.2019)
```
cd /usr/src/
wget https://git.kernel.org/torvalds/t/linux-5.3-rc1.tar.gz
tar xvfz linux-5.3-rc1.tar.gz
cd linux-5.3-rc1/
cp /boot/config* .config
```

```
make oldconfig
make bzImage
make modules
make
make modules_install
make install

reboot
```

###### Принудительно заменяю выбор ядра в загрузчике
```
nano /etc/default/grub
GRUB_DEFAULT="Linux 5.3.0-rc1"

grub2-mkconfig -o /boot/grub2/grub.cfg
reboot

[root@KernelVM vagrant]# uname -r
5.3.0-rc1
```

---

#### Прилагаю файлы полученые в ходе выполнения ДЗ1:
- [.config](config)
- [yum.log](yum.log)
