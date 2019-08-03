# Домашнее задание 2 (OTUS Linux 2019 - 07)
###### - Добавить в Vagrantfile еще дисков;
###### - Сломать/починить raid;
###### - Собрать R0/R5/R10 - на выбор;
###### - Создать на рейде GPT раздел и 5 партиций.
###### В качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда.
###### * Доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом.
###### ** Перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).
###### Критерии оценки: 
###### - 4 - сдан Vagrantfile и скрипт для сборки, который можно запустить на поднятом образе;
###### - 5 - сделано доп задание.

---

####### Использую Vagrantfile (без автоматической сборки RAID)
- [Vagrantfile, без автоматической сборки RAID](Vagrantfile)

####### Входим под root
```
sudo su
```

####### Устанавливаю необходимое для работы ПО
```
yum install mdadm nano mc
```

####### Проверяю подключение новых дисков
```
[root@hw2 vagrant]# fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef88

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdb: 268 MB, 268435456 bytes, 524288 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 268 MB, 268435456 bytes, 524288 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdd: 268 MB, 268435456 bytes, 524288 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sde: 268 MB, 268435456 bytes, 524288 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

####### Зануляем суперблоки
```
[root@hw2 vagrant]# mdadm --zero-superblock --force /dev/sd{b,c,d,e}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
```

####### Создаем RAID5 из трех дисков (sdb, sdc, sdd), диск sde оставим для восстановления будущего RAID
```
[root@hw2 vagrant]# mdadm --create --verbose /dev/md5 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 260096K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md5 started.
```

####### Проверка правильности сборки
```
[root@hw2 vagrant]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md5 : active raid5 sdd[3] sdc[1] sdb[0]
      520192 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]

unused devices: <none>
```

####### Проверяю что массив появился в устройствах
```
[root@hw2 vagrant]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part  /
sdb      8:16   0  256M  0 disk
└─md5    9:5    0  508M  0 raid5
sdc      8:32   0  256M  0 disk
└─md5    9:5    0  508M  0 raid5
sdd      8:48   0  256M  0 disk
└─md5    9:5    0  508M  0 raid5
sde      8:64   0  256M  0 disk
```

```
[root@hw2 vagrant]# mdadm -D /dev/md5
/dev/md5:
           Version : 1.2
     Creation Time : Thu Aug  1 15:44:30 2019
        Raid Level : raid5
        Array Size : 520192 (508.00 MiB 532.68 MB)
     Used Dev Size : 260096 (254.00 MiB 266.34 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Thu Aug  1 15:44:39 2019
             State : clean
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : hw2.otus.ru:5  (local to host hw2.otus.ru)
              UUID : 0b2a8dd0:c31da3f0:11282864:1929fb24
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       3       8       48        2      active sync   /dev/sdd
```

####### Создание конфигурационного файла mdadm.conf
```
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

####### Создаем раздел GPT на RAID
```
parted -s /dev/md5 mklabel gpt
```

####### Размечаем диск
```
parted /dev/md5 mkpart primary ext4 0% 20%
parted /dev/md5 mkpart primary ext4 20% 40%
parted /dev/md5 mkpart primary ext4 40% 60%
parted /dev/md5 mkpart primary ext4 60% 80%
parted /dev/md5 mkpart primary ext4 80% 100%
```

```
[root@hw2 vagrant]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda         8:0    0   40G  0 disk
└─sda1      8:1    0   40G  0 part  /
sdb         8:16   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md
  ├─md5p2 259:6    0  101M  0 md
  ├─md5p3 259:0    0  102M  0 md
  ├─md5p4 259:1    0  101M  0 md
  └─md5p5 259:2    0  101M  0 md
sdc         8:32   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md
  ├─md5p2 259:6    0  101M  0 md
  ├─md5p3 259:0    0  102M  0 md
  ├─md5p4 259:1    0  101M  0 md
  └─md5p5 259:2    0  101M  0 md
sdd         8:48   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md
  ├─md5p2 259:6    0  101M  0 md
  ├─md5p3 259:0    0  102M  0 md
  ├─md5p4 259:1    0  101M  0 md
  └─md5p5 259:2    0  101M  0 md
sde         8:64   0  256M  0 disk
```

####### Создаем файловую систему в разделах
```
[root@hw2 vagrant]# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md5p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25896 inodes, 103424 blocks
5171 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1992 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25896 inodes, 103424 blocks
5171 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1992 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
26208 inodes, 104448 blocks
5222 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
2016 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25896 inodes, 103424 blocks
5171 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1992 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25896 inodes, 103424 blocks
5171 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1992 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```

####### Монитруем
```
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md5p$i /raid/part$i; done
```

```
[root@hw2 raid]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda         8:0    0   40G  0 disk
└─sda1      8:1    0   40G  0 part  /
sdb         8:16   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
sdc         8:32   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
sdd         8:48   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
sde         8:64   0  256M  0 disk
```

####### Заполняем fstab
```
[root@hw2 raid]# nano /etc/fstab
[root@hw2 raid]# cat /etc/fstab
#
# /etc/fstab
# Created by anaconda on Sat Jun  1 17:13:31 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=8ac075e3-1124-4bb6-bef7-a6811bf8b870       /               xfs     defaults 0 0
/swapfile                                       none            swap    defaults 0 0
/dev/md5p1                                      /raid/part1     ext4    defaults 0 0
/dev/md5p2                                      /raid/part2     ext4    defaults 0 0
/dev/md5p3                                      /raid/part3     ext4    defaults 0 0
/dev/md5p4                                      /raid/part4     ext4    defaults 0 0
/dev/md5p5                                      /raid/part5     ext4    defaults 0 0
```

####### Создаем файлы в разделах
```
touch /raid/part1/part1file.txt
touch /raid/part2/part2file.txt
touch /raid/part3/part3file.txt
touch /raid/part4/part4file.txt
touch /raid/part5/part5file.txt
```

####### Ломаем RAID
```
[root@hw2 raid]# mdadm /dev/md5 --fail /dev/sdd
mdadm: set /dev/sdd faulty in /dev/md5
```

####### Проверяем что натворили
```
[root@hw2 raid]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md5 : active raid5 sdd[3](F) sdc[1] sdb[0]
      520192 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [UU_]

unused devices: <none>
```

```
[root@hw2 raid]# mdadm -D /dev/md5
/dev/md5:
           Version : 1.2
     Creation Time : Thu Aug  1 15:44:30 2019
        Raid Level : raid5
        Array Size : 520192 (508.00 MiB 532.68 MB)
     Used Dev Size : 260096 (254.00 MiB 266.34 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Thu Aug  1 16:34:24 2019
             State : clean, degraded
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : hw2.otus.ru:5  (local to host hw2.otus.ru)
              UUID : 0b2a8dd0:c31da3f0:11282864:1929fb24
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed

       3       8       48        -      faulty   /dev/sdd
```

####### Удаляем "сломанный диск"
```
[root@hw2 /]# mdadm /dev/md5 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md5
```

####### Вставляем новый диск
```
[root@hw2 /]# mdadm /dev/md5 --add /dev/sde
mdadm: added /dev/sde
```

####### Проверяем
```
[root@hw2 /]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md5 : active raid5 sde[3] sdc[1] sdb[0]
      520192 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]

unused devices: <none>
```

```
[root@hw2 /]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda         8:0    0   40G  0 disk
└─sda1      8:1    0   40G  0 part  /
sdb         8:16   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
sdc         8:32   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
sdd         8:48   0  256M  0 disk
sde         8:64   0  256M  0 disk
└─md5       9:5    0  508M  0 raid5
  ├─md5p1 259:5    0  101M  0 md    /raid/part1
  ├─md5p2 259:6    0  101M  0 md    /raid/part2
  ├─md5p3 259:0    0  102M  0 md    /raid/part3
  ├─md5p4 259:1    0  101M  0 md    /raid/part4
  └─md5p5 259:2    0  101M  0 md    /raid/part5
```

####### Перезагружаемся и проверяем всё ли работает
```
reboot

D:\Otus\2.mdadm>Vagrant ssh
Last login: Thu Aug  1 16:02:35 2019 from 10.0.2.2
[vagrant@hw2 ~]$ sudo su
[root@hw2 vagrant]# cat /raid/part1/
lost+found/    part1file.txt
[root@hw2 vagrant]# cat /raid/part2/
lost+found/    part2file.txt
[root@hw2 vagrant]# cat /raid/part2/
```

### Файлы на месте. Данную часть ДЗ2 считаю выполненой. Был собран RAID5, прописан mdadm.conf, сломан\починен RAID5, созданы партиции, настроен /etc/fstab

---

# Использую Vagrantfile_AutoRaid (с автоматической сборкой RAID1)
- [Vagrantfile, автоматическая сборка RAID1](Vagrantfile_AutoRaid)

####### Проверяем ВМ после запуска
```
[root@hw2 vagrant]# cat /proc/mdstat
Personalities : [raid1]
md1 : active raid1 sdc[1] sdb[0]
      47185856 blocks [2/2] [UU]
```

```
[root@hw2 vagrant]# mdadm -D /dev/md1
/dev/md1:
           Version : 0.90
     Creation Time : Fri Aug  2 19:15:58 2019
        Raid Level : raid1
        Array Size : 5242816 (5.00 GiB 5.37 GB)
     Used Dev Size : 5242816 (5.00 GiB 5.37 GB)
      Raid Devices : 2
     Total Devices : 2
   Preferred Minor : 1
       Persistence : Superblock is persistent

       Update Time : Fri Aug  2 19:17:40 2019
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              UUID : 6afc6fe5:0c4a1500:f6902696:05fbfb28 (local to host hw2.2.otus.ru)
            Events : 0.18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
```

### В результате выполнения [CreateRaid.sh](CreateRaid.sh) при запуске [Vagrantfile](Vagrantfile_AutoRaid) был автоматически собран RAID1

# Приступаю к выполнению задания с двумя **звездами.

---

### Немного поменял Vagrantfile и размер дисков увеличил до 45ГБ, при запуске ВМ так же был сделан md1, но большего размера (:HDD_SIZE => 46080,)

####### Копируем полностью разделы, с sda на md1:
```
[root@hw2 vagrant]# sfdisk -d /dev/sda | sfdisk /dev/md1
Checking that no-one is using this disk right now ...
OK

Disk /dev/md1: 11796464 cylinders, 2 heads, 4 sectors/track
sfdisk:  /dev/md1: unrecognized partition table type

Old situation:
sfdisk: No partitions found

New situation:
Units: sectors of 512 bytes, counting from 0

   Device Boot    Start       End   #sectors  Id  System
/dev/md1p1   *      2048  83886079   83884032  83  Linux
/dev/md1p2             0         -          0   0  Empty
/dev/md1p3             0         -          0   0  Empty
/dev/md1p4             0         -          0   0  Empty
Successfully wrote the new partition table

Re-reading the partition table ...

If you created or changed a DOS partition, /dev/foo7, say, then use dd(1)
to zero the first 512 bytes:  dd if=/dev/zero of=/dev/foo7 bs=512 count=1
(See fdisk(8).)
```

####### Форматируем получившийся /dev/md1p1:
```
[root@hw2 vagrant]# mkfs.ext4 /dev/md1p1
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
2621440 inodes, 10485504 blocks
524275 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2157969408
320 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
```

####### Создаем папку для монтирования
```
[root@hw2 vagrant]# mkdir /raid
[root@hw2 vagrant]# mount /dev/md1p1 /raid
```

####### Копируем текущую систему на /dev/md1p1:
```
[root@hw2 vagrant]# rsync -axu / /raid/
```

####### Монтируем информацию о текущей системе в наш новый корень и делаем chroot в него
```
mount --bind /proc /raid/proc
mount --bind /dev /raid/dev
mount --bind /sys /raid/sys
mount --bind /run /raid/run
chroot /raid/
```

####### Получаем uuid /dev/md1p1 и вносим его в fstab
```
[root@hw2 /]# blkid /dev/md1p1
/dev/md1p1: UUID="5c1443f3-169d-4e9b-9f50-2a7d9351b461" TYPE="ext4"
```

```
[root@hw2 /]# nano /etc/fstab
[root@hw2 /]# cat /etc/fstab
#
# /etc/fstab Created by anaconda on Sat Jun 1 17:13:31 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk' See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=5c1443f3-169d-4e9b-9f50-2a7d9351b461 / ext4 defaults 0 0
/swapfile none swap defaults 0 0
```

####### Создаем конфиг для mdadm, чтоб md1 не сменил имя при перезагрузке:
```
mdadm --detail --scan > /etc/mdadm.conf 

[root@hw2 /]# cat /etc/mdadm.conf
ARRAY /dev/md1 metadata=0.90 UUID=b3db3051:6feca523:f6902696:05fbfb28
```

####### Делаем новый initramfs
```
mv /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img.backup
dracut /boot/initramfs-$(uname -r).img $(uname -r)
```

####### Передаем ядру опцию «rd.auto=1» явно через «GRUB», для этого, добавляем ее в «GRUB_CMDLINE_LINUX»
```
[root@hw2 boot]# nano /etc/default/grub
[root@hw2 boot]# cat /etc/default/grub
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="(sed s, release .*,,g /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.auto=1"
GRUB_DISABLE_RECOVERY="true"
```

####### Перепишем конфиг «GRUB» и установим его на диск sdb:
```
[root@hw2 boot]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-957.12.2.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img
done
```

```
[root@hw2 boot]# grub2-install /dev/sdb
Installing for i386-pc platform.
Installation finished. No error reported.
```

####### Проверяем записалось ли
```
[root@hw2 boot]# cat /boot/grub2/grub.cfg | grep 5c1443f3-169d-4e9b-9f50-2a7d9351b461
menuentry 'CentOS Linux (3.10.0-957.12.2.el7.x86_64) 7 (Core)' --class _sed --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-957.12.2.el7.x86_64-advanced-5c1443f3-169d-4e9b-9f50-2a7d9351b461' {
          search --no-floppy --fs-uuid --set=root --hint='mduuid/b3db30516feca523f690269605fbfb28,msdos1'  5c1443f3-169d-4e9b-9f50-2a7d9351b461
          search --no-floppy --fs-uuid --set=root 5c1443f3-169d-4e9b-9f50-2a7d9351b461
        linux16 /boot/vmlinuz-3.10.0-957.12.2.el7.x86_64 root=UUID=5c1443f3-169d-4e9b-9f50-2a7d9351b461 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.auto=1
```

####### Вывод lsblk до перезагрузки
```
[root@hw2 boot]# exit
exit
[root@hw2 vagrant]# lsblk
NAME      MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda         8:0    0  40G  0 disk
└─sda1      8:1    0  40G  0 part  /
sdb         8:16   0  45G  0 disk
├─sdb1      8:17   0  40G  0 part
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:1    0  40G  0 md    /raid
sdc         8:32   0  45G  0 disk
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:1    0  40G  0 md    /raid
```

####### Перезагружаемся
```
[root@hw2 vagrant]# umount /raid/proc
[root@hw2 vagrant]# umount /raid/dev
[root@hw2 vagrant]# umount /raid/sys
umount: /raid/sys: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@hw2 vagrant]# umount -l /raid/sys
[root@hw2 vagrant]# umount /raid/run
[root@hw2 vagrant]# umount /raid
[root@hw2 vagrant]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
```

####### Проверяю
```
D:\Otus\2.mdadm>vagrant ssh
Last login: Sat Aug  3 16:25:28 2019 from 10.0.2.2
[vagrant@hw2 ~]$ sudo su
[root@hw2 vagrant]# lsblk
NAME      MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda         8:0    0  40G  0 disk
└─sda1      8:1    0  40G  0 part  /
sdb         8:16   0  45G  0 disk
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:0    0  40G  0 md
sdc         8:32   0  45G  0 disk
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:0    0  40G  0 md
```

####### Загрузился под старой системой (не то что нужно).. Отключаю машину, в virtualbox вручную удаляю первый hdd (не знаю как обозначить другой boot в bios virtualbox)
```
[root@hw2 vagrant]# shutdown -h now
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

D:\Otus\2.mdadm>vagrant up
Bringing machine 'hw2.2.otus.ru' up with 'virtualbox' provider...
==> hw2.2.otus.ru: Checking if box 'centos/7' version '1905.1' is up to date...
==> hw2.2.otus.ru: Clearing any previously set forwarded ports...
==> hw2.2.otus.ru: Clearing any previously set network interfaces...
==> hw2.2.otus.ru: Preparing network interfaces based on configuration...
    hw2.2.otus.ru: Adapter 1: nat
    hw2.2.otus.ru: Adapter 2: hostonly
==> hw2.2.otus.ru: Forwarding ports...
    hw2.2.otus.ru: 22 (guest) => 2222 (host) (adapter 1)
==> hw2.2.otus.ru: Running 'pre-boot' VM customizations...
==> hw2.2.otus.ru: Booting VM...
==> hw2.2.otus.ru: Waiting for machine to boot. This may take a few minutes...
    hw2.2.otus.ru: SSH address: 127.0.0.1:2222
    hw2.2.otus.ru: SSH username: vagrant
    hw2.2.otus.ru: SSH auth method: private key
    hw2.2.otus.ru: Warning: Connection reset. Retrying...
    hw2.2.otus.ru: Warning: Connection aborted. Retrying...
The configured shell (config.ssh.shell) is invalid and unable
to properly execute commands. The most common cause for this is
using a shell that is unavailable on the system. Please verify
you're using the full path to the shell and that the shell is
executable by the SSH user.
```

####### Система загрузилась, но через ключ не зашло..
```
D:\Otus\2.mdadm>vagrant ssh
Last login: Sat Aug  3 16:56:00 2019 from 10.0.2.2
/bin/bash: Permission denied
Connection to 127.0.0.1 closed.
```

####### Загрузиться не получилось (как оказалось, виноват selinux, обсуждали тут https://otus-linux.slack.com/archives/CLP365L4V/p1564852412125600), подключил обратно sda, загрузился и поправил
```
[root@hw2 vagrant]# mkdir /raid
[root@hw2 vagrant]# mount /dev/md1p1 /raid
[root@hw2 /]# nano /raid/etc/selinux/config
[root@hw2 /]# [root@hw2 /]# cat /raid/etc/selinux/config

# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
[root@hw2 /]# umount /raid
[root@hw2 /]# shutdown -h now
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
```

####### Отключил первый диск снова, пробую повторить
```
D:\Otus\2.mdadm>vagrant ssh
Last login: Sat Aug  3 16:25:28 2019 from 10.0.2.2
Last login: Sat Aug  3 16:25:28 2019 from 10.0.2.2
[vagrant@hw2 ~]$ sudo su
[root@hw2 vagrant]# lsblk
NAME      MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda         8:0    0  45G  0 disk
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:0    0  40G  0 md    /
sdb         8:16   0  45G  0 disk
└─md1       9:1    0  45G  0 raid1
  └─md1p1 259:0    0  40G  0 md    /
```

### На этом этапе считаю задание ДЗ2 выполненым в полном объеме.
