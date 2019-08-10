# Домашнее задание 3 (OTUS Linux 2019 - 07)
###### Работа с LVM
###### на имеющемся образе
###### /dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /
###### 
###### уменьшить том под / до 8G
###### выделить том под /home
###### выделить том под /var
###### /var - сделать в mirror
###### /home - сделать том для снэпшотов
###### прописать монтирование в fstab
###### попробовать с разными опциями и разными файловыми системами ( на выбор)
###### - сгенерить файлы в /home/
###### - снять снэпшот
###### - удалить часть файлов
###### - восстановится со снэпшота
###### - залоггировать работу можно с помощью утилиты script
###### 
###### * на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt
###### Критерии оценки: основная часть обязательна
###### задание со звездочкой +1 балл

---

#### Уменьшаем том до 8 Гб

###### Ставим необходимые утилиты
```
yum install lvm2 xfsdump -y
```

###### Подготовим временный раздел для корневого тома. Сперва смотрим какие разделы есть
```
[root@lvm /]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
+-sda1                    8:1    0    1M  0 part
+-sda2                    8:2    0    1G  0 part /boot
L-sda3                    8:3    0   39G  0 part
  +-VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  L-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

###### Используем для этого sdb, т.к. самый большой свободный диск. Делаем разметку диска (Physical Volume)
```
[root@lvm /]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```

###### Создаем Volume Group (группу томов)
```
[root@lvm /]# vgcreate vg_tmp_root /dev/sdb
  Volume group "vg_tmp_root" successfully created
```

###### Создаем логический раздел
```
[root@lvm /]# lvcreate -n lv_tmp_root -l +100%FREE /dev/vg_tmp_root
  Logical volume "lv_tmp_root" created.
```

###### Проверяю
```
[root@lvm /]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVol00   253:0    0 37.5G  0 lvm  /
  L-VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:2    0   10G  0 lvm
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

```
[root@lvm /]# vgdisplay vg_tmp_root
  --- Volume group ---
  VG Name               vg_tmp_root
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2559 / <10.00 GiB
  Free  PE / Size       0 / 0
  VG UUID               1sWBXu-Isoy-s5Gb-2ljO-hnDP-divO-BG74v5
```


###### Создадим файловую систему XFS 
```
[root@lvm /]# mkfs.xfs /dev/vg_tmp_root/lv_tmp_root
meta-data=/dev/vg_tmp_root/lv_tmp_root isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

###### Монтируем новый VL в каталог /mnt:
```
mount /dev/vg_tmp_root/lv_tmp_root /mnt
```

###### Напоминаю себе где корневой раздел
```
[root@lvm vagrant]# lsblk | grep /
+-sda2                      8:2    0    1G  0 part /boot
  +-vg_tmp_root-lv_tmp_root   253:0    0 37.5G  0 lvm  /
L-vg_tmp_root-lv_tmp_root 253:2    0   10G  0 lvm  /mnt
```

###### Смотрю полный путь устройства (dev) для удобства копирования
```
[root@lvm ~]# lvdisplay | grep 'LV Path'
  LV Path                /dev/VolGroup00/LogVol00
  LV Path                /dev/VolGroup00/LogVol01
  LV Path                /dev/vg_tmp_root/lv_tmp_root
```

###### Копирую систему на временный раздел
```
[root@lvm ~]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Wed Aug  7 15:06:55 2019
xfsdump: session id: 5d680213-7eb4-4791-a1e0-4f358c276389
xfsdump: session label: ""
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 828731264 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description:
xfsrestore: hostname: lvm
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/VolGroup00-LogVol00
xfsrestore: session time: Wed Aug  7 15:06:55 2019
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: b60e9498-0baa-4d9f-90aa-069048217fee
xfsrestore: session id: 5d680213-7eb4-4791-a1e0-4f358c276389
xfsrestore: media id: 96b50f0e-db3d-4290-a50c-6a5bc429d2d2
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 3133 directories and 27116 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 800414960 bytes
xfsdump: dump size (non-dir files) : 785139384 bytes
xfsdump: dump complete: 31 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 32 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

###### Монитруем каталоги
```
[root@lvm ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

###### Делаем chroot
```
[root@lvm ~]# chroot /mnt/
[root@lvm /]#
```

###### Правим fstab
```
[root@lvm /]# nano /etc/fstab
[root@lvm /]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/vg_tmp_root-lv_tmp_root 		/	xfs	defaults 0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc 	/boot	xfs     defaults 0 0
/dev/mapper/VolGroup00-LogVol01 		swap	swap    defaults 0 0
```

###### Делаем новый initramfs
```
[root@lvm /]# cd boot
[root@lvm boot]# for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 60-persistent-storage-dm.rules
Skipping udev rule: 55-dm.rules
*** Including module: kernel-modules ***
Omitting driver floppy
*** Including module: lvm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 56-lvm.rules
Skipping udev rule: 60-persistent-storage-lvm.rules
*** Including module: qemu ***
*** Including module: resume ***
*** Including module: rootfs-block ***
*** Including module: terminfo ***
*** Including module: udev-rules ***
Skipping udev rule: 40-redhat-cpu-hotplug.rules
Skipping udev rule: 91-permissions.rules
*** Including module: biosdevname ***
*** Including module: systemd ***
*** Including module: usrmount ***
*** Including module: base ***
*** Including module: fs-lib ***
*** Including module: shutdown ***
*** Including modules done ***
*** Installing kernel module dependencies and firmware ***
*** Installing kernel module dependencies and firmware done ***
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

###### Перепишем конфиг «GRUB»
```
[root@lvm boot]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

###### Проверяем запись с загрузкой vl (сделал изменение VolGroup00/LogVol00 на vg_tmp_root/lv_tmp_root)
```
[root@lvm boot]# cat /boot/grub2/grub.cfg | grep lv_tmp_root
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/vg_tmp_root-lv_tmp_root ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=vg_tmp_root/lv_tmp_root rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet
```

###### Вывод lsblk до перезагрузки
```
[root@lvm boot]# exit
exit
[root@lvm ~]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /mnt/boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVol00   253:0    0 37.5G  0 lvm  /
  L-VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:2    0   10G  0 lvm  /mnt
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

###### Презагружаемся и проверям, корневой раздел теперь на vg_tmp_root-lv_tmp_root
```
[root@lvm vagrant]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVol00   253:0    0 37.5G  0 lvm
  L-VolGroup00-LogVol01   253:2    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:1    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```


###### Продолжаем перенос, удаляем логический том:
```
[root@lvm vagrant]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```

```
[root@lvm vagrant]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /boot
L-sda3                      8:3    0   39G  0 part
  L-VolGroup00-LogVol01   253:2    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:1    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

###### Создаем новый, но с нужным размером
```
[root@lvm vagrant]# lvcreate -n LogVolNEW -L 8G /dev/VolGroup00
  Logical volume "LogVolNEW" created.
```

```
[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVolNEW
meta-data=/dev/VolGroup00/LogVolNEW isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

###### Монтируем
```
[root@lvm vagrant]# mount /dev/VolGroup00/LogVolNEW /mnt

[root@lvm vagrant]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
  L-VolGroup00-LogVolNEW  253:2    0    8G  0 lvm  /mnt
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

###### Возвращаем обратно содержимое корня:
```
[root@lvm ~]# xfsdump -J - /dev/vg_tmp_root/lv_tmp_root | xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Wed Aug  7 16:01:58 2019
xfsdump: session id: 13478d53-a065-4e25-b613-a0891f78b9e2
xfsdump: session label: ""
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 827262400 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description:
xfsrestore: hostname: lvm
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/vg_tmp_root-lv_tmp_root
xfsrestore: session time: Wed Aug  7 16:01:58 2019
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: de45b1f3-b4e4-4bb0-90ba-f95d971ffefb
xfsrestore: session id: 13478d53-a065-4e25-b613-a0891f78b9e2
xfsrestore: media id: 1d112027-eb55-49c5-bd66-b589a063a2f6
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 3137 directories and 27121 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 799337192 bytes
xfsdump: dump size (non-dir files) : 784071952 bytes
xfsdump: dump complete: 21 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 21 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

```
[root@lvm /]# nano /etc/fstab
[root@lvm /]# cat /etc/fstab
#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVolNEW		/       xfs     defaults 0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc       /boot   xfs     defaults 0 0
/dev/mapper/VolGroup00-LogVol01                 swap    swap    defaults 0 0
```

```
[root@lvm /]# cd boot
[root@lvm boot]# for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 60-persistent-storage-dm.rules
Skipping udev rule: 55-dm.rules
*** Including module: kernel-modules ***
Omitting driver floppy
*** Including module: lvm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 56-lvm.rules
Skipping udev rule: 60-persistent-storage-lvm.rules
*** Including module: qemu ***
*** Including module: resume ***
*** Including module: rootfs-block ***
*** Including module: terminfo ***
*** Including module: udev-rules ***
Skipping udev rule: 40-redhat-cpu-hotplug.rules
Skipping udev rule: 91-permissions.rules
*** Including module: biosdevname ***
*** Including module: systemd ***
*** Including module: usrmount ***
*** Including module: base ***
*** Including module: fs-lib ***
*** Including module: shutdown ***
*** Including modules done ***
*** Installing kernel module dependencies and firmware ***
*** Installing kernel module dependencies and firmware done ***
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

```
[root@lvm boot]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

```
[root@lvm boot]# cat /boot/grub2/grub.cfg | grep VolGroup00
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVolNEW ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVolNEW rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet
```

###### Вывод lsblk до перезагрузки
```
[root@lvm boot]# exit
exit
[root@lvm mnt]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /mnt/boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
  L-VolGroup00-LogVolNEW  253:2    0    8G  0 lvm  /mnt
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

###### Презагружаемся и проверям, корневой раздел теперь на VolGroup00-LogVolNEW
```
[root@lvm vagrant]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk
+-sda1                      8:1    0    1M  0 part
+-sda2                      8:2    0    1G  0 part /boot
L-sda3                      8:3    0   39G  0 part
  +-VolGroup00-LogVolNEW  253:0    0    8G  0 lvm  /
  L-VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk
L-vg_tmp_root-lv_tmp_root 253:2    0   10G  0 lvm
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
```

###### Удаляем том, группу и снимаем lvm-метку с диска, который нами использовался как временный (sdb):
```
[root@lvm vagrant]# lvremove /dev/vg_tmp_root/lv_tmp_root
Do you really want to remove active logical volume vg_tmp_root/lv_tmp_root? [y/n]: y
  Logical volume "lv_tmp_root" successfully removed
```

```
[root@lvm vagrant]# vgremove vg_tmp_root
  Volume group "vg_tmp_root" successfully removed
```

```
[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

###### Смотрю что натворил
```
[root@lvm vagrant]# vgdisplay
  --- Volume group ---
  VG Name               VolGroup00
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  7
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <38.97 GiB
  PE Size               32.00 MiB
  Total PE              1247
  Alloc PE / Size       304 / 9.50 GiB
  Free  PE / Size       943 / <29.47 GiB
  VG UUID               SA8LTU-F2yz-FEV1-RdgT-hw0Z-iRxh-yHFKuU
```

```
[root@lvm vagrant]# lvdisplay /dev/VolGroup00/LogVolNEW
  --- Logical volume ---
  LV Path                /dev/VolGroup00/LogVolNEW
  LV Name                LogVolNEW
  VG Name                VolGroup00
  LV UUID                jPD5Ff-Qnkj-fLqG-295K-W2rw-HZ5A-v6BBob
  LV Write Access        read/write
  LV Creation host, time lvm, 2019-08-07 15:54:21 +0000
  LV Status              available
  # open                 1
  LV Size                8.00 GiB
  Current LE             256
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```

#### Перенос корневого раздела завершен, приступаю к другой части ДЗ3

###### Создаем раздел под /home
```
[root@lvm vagrant]# lvcreate -n LogVolNewHOME -L 500M /dev/VolGroup00
  Rounding up size to full physical extent 512.00 MiB
  Logical volume "LogVolNewHOME" created.
```

###### Перенесем /home в отдельный раздел ext4
```
[root@lvm vagrant]# mkfs.ext4 /dev/mapper/VolGroup00-LogVolNewHOME
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
32768 inodes, 131072 blocks
6553 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=134217728
4 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```

```
mkdir /mnt/newhome
mount /dev/mapper/VolGroup00-LogVolNewHOME /mnt/newhome
```

```
cp -a /home/* /mnt/newhome
```

###### Правим fstab
```
[root@lvm newhome]# nano /etc/fstab
[root@lvm newhome]# cat /etc/fstab
#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVolNewHOME		/home	ext4	defaults 0 0
/dev/mapper/VolGroup00-LogVolNEW                /       xfs     defaults 0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc       /boot   xfs     defaults 0 0
/dev/mapper/VolGroup00-LogVol01                 swap    swap    defaults 0 0
```


###### Перезагружаемся и проверям
```
[root@lvm mnt]# lsblk
NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                            8:0    0   40G  0 disk
+-sda1                         8:1    0    1M  0 part
+-sda2                         8:2    0    1G  0 part /boot
L-sda3                         8:3    0   39G  0 part
  +-VolGroup00-LogVolNEW     253:0    0    8G  0 lvm  /
  +-VolGroup00-LogVol01      253:1    0  1.5G  0 lvm  [SWAP]
  L-VolGroup00-LogVolNewHOME 253:2    0  512M  0 lvm  /home
sdb                            8:16   0   10G  0 disk
sdc                            8:32   0    2G  0 disk
sdd                            8:48   0    1G  0 disk
sde                            8:64   0    1G  0 disk
```

#### Сделаем зеркальный рейд на двух дисках для var
```
[root@lvm ~]# pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
```

```
[root@lvm ~]# vgcreate VolGroupVAR /dev/sd{d,e}
  Volume group "VolGroupVAR" successfully created
```

```
[root@lvm ~]# lvcreate -l+80%FREE -m1 -n LogVolNewVarMirror VolGroupVAR
  Logical volume "LogVolNewVarMirror" created.
```

```
[root@lvm ~]# lvs
  LV                 VG          Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol01           VolGroup00  -wi-ao----   1.50g
  LogVolNEW          VolGroup00  -wi-ao----   8.00g
  LogVolNewHOME      VolGroup00  -wi-ao---- 512.00m
  LogVolNewVarMirror VolGroupVAR rwi-a-r--- 816.00m                                    100.00
```


#### Перенесем /var в отдельный раздел ext3 (зеркальный)
###### Создал LogVolNewVarMirror (лог не сохранил), продолжаю
```
[root@lvm mnt]# mkfs.ext3 /dev/mapper/VolGroupVAR-LogVolNewVarMirror
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
52304 inodes, 208896 blocks
10444 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=213909504
7 block groups
32768 blocks per group, 32768 fragments per group
7472 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
```
mkdir /mnt/newvar
mount /dev/mapper/VolGroupVAR-LogVolNewVarMirror /mnt/newvar
```

```
cp -a /var/* /mnt/newvar
```

###### Правим fstab
```
[root@lvm newhome]# nano /etc/fstab
[root@lvm newhome]# cat /etc/fstab
#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroupVAR-LogVolNewVarMirror	/var	ext3	defaults 0 0
/dev/mapper/VolGroup00-LogVolNewHOME		/home	ext4	defaults 0 0
/dev/mapper/VolGroup00-LogVolNEW                /       xfs     defaults 0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc       /boot   xfs     defaults 0 0
/dev/mapper/VolGroup00-LogVol01                 swap    swap    defaults 0 0
```


###### Перезагружаемся и проверям
```
[root@lvm vagrant]# lsblk
NAME                                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                         8:0    0   40G  0 disk
+-sda1                                      8:1    0    1M  0 part
+-sda2                                      8:2    0    1G  0 part /boot
L-sda3                                      8:3    0   39G  0 part
  +-VolGroup00-LogVolNEW                  253:0    0    8G  0 lvm  /
  +-VolGroup00-LogVol01                   253:1    0  1.5G  0 lvm  [SWAP]
  L-VolGroup00-LogVolNewHOME              253:3    0  512M  0 lvm  /home
sdb                                         8:16   0   10G  0 disk
sdc                                         8:32   0    2G  0 disk
sdd                                         8:48   0    1G  0 disk
+-VolGroupVAR-LogVolNewVarMirror_rmeta_0  253:2    0    4M  0 lvm
¦ L-VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
L-VolGroupVAR-LogVolNewVarMirror_rimage_0 253:4    0  816M  0 lvm
  L-VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
sde                                         8:64   0    1G  0 disk
+-VolGroupVAR-LogVolNewVarMirror_rmeta_1  253:5    0    4M  0 lvm
¦ L-VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
L-VolGroupVAR-LogVolNewVarMirror_rimage_1 253:6    0  816M  0 lvm
  L-VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
```

###### Для себя
```
[root@lvm vagrant]# lvs
  LV                 VG          Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol01           VolGroup00  -wi-ao----   1.50g
  LogVolNEW          VolGroup00  -wi-ao----   8.00g
  LogVolNewHOME      VolGroup00  -wi-ao---- 512.00m
  LogVolNewVarMirror VolGroupVAR rwi-aor--- 816.00m                                    100.00
```

```
[root@lvm vagrant]# vgs
  VG          #PV #LV #SN Attr   VSize   VFree
  VolGroup00    1   3   0 wz--n- <38.97g <28.97g
  VolGroupVAR   2   1   0 wz--n-   1.99g 400.00m
```

```
[root@lvm vagrant]# pvs
  PV         VG          Fmt  Attr PSize    PFree
  /dev/sda3  VolGroup00  lvm2 a--   <38.97g <28.97g
  /dev/sdd   VolGroupVAR lvm2 a--  1020.00m 200.00m
  /dev/sde   VolGroupVAR lvm2 a--  1020.00m 200.00m
```

#### Создаю снапшоты

###### Сгенерируем файлы в /home/:
```
[root@lvm vagrant]# touch /home/file{1..30}
```

```
[root@lvm /]# ls /home
file1   file11  file13  file15  file17  file19  file20  file22  file24  file26  file28  file3   file4  file6  file8  lost+found
file10  file12  file14  file16  file18  file2   file21  file23  file25  file27  file29  file30  file5  file7  file9  vagrant
```


###### Снять снапшот:
```
[root@lvm home]# lvcreate -L 100MB -s -n HomeSnapshot /dev/VolGroup00/LogVolNewHOME
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "HomeSnapshot" created.
```

###### Удаляем файлы
```
[root@lvm home]# rm -f /home/file{11..20}
```

```
[root@lvm home]# ls /home
file1  file10  file2  file21  file22  file23  file24  file25  file26  file27  file28  file29  file3  file30  file4  file5  file6  file7  file8  file9  lost+found  vagrant
```

```
[root@lvm /]# lvscan
  ACTIVE            '/dev/VolGroup00/LogVol01' [1.50 GiB] inherit
  ACTIVE            '/dev/VolGroup00/LogVolNEW' [8.00 GiB] inherit
  ACTIVE   Original '/dev/VolGroup00/LogVolNewHOME' [512.00 MiB] inherit
  ACTIVE   Snapshot '/dev/VolGroup00/HomeSnapshot' [128.00 MiB] inherit
  ACTIVE            '/dev/VolGroupVAR/LogVolNewVarMirror' [816.00 MiB] inherit
```

###### Восстанавливаем из снапшота
```
[root@lvm /]# lvconvert --merge /dev/VolGroup00/HomeSnapshot
  Delaying merge since origin is open.
  Merging of snapshot VolGroup00/HomeSnapshot will occur on next activation of VolGroup00/LogVolNewHOME.
```

###### Перезагружаемся
```
D:\Otus\3.LVM>Vagrant ssh
Last login: Wed Aug  7 18:23:11 2019 from 10.0.2.2
[vagrant@lvm ~]$ sudo su
[root@lvm vagrant]# ls /home
file1   file11  file13  file15  file17  file19  file20  file22  file24  file26  file28  file3   file4  file6  file8  lost+found
file10  file12  file14  file16  file18  file2   file21  file23  file25  file27  file29  file30  file5  file7  file9  vagrant
```

###### Файлы были успешно восстановлены


### Приступаю к выполнению задания с звездой*


###### _* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt_
###### _Критерии оценки: основная часть обязательна_
###### _задание со звездочкой +1 балл_

###### Устанавливаем zfs
```
yum install http://download.zfsonlinux.org/epel/zfs-release.el7_6.noarch.rpm
sed -i '12s/enabled=0/enabled=1/' /etc/yum.repos.d/zfs.repo
yum install zfs -y
```

###### Поднимаем lvm на двух оставшихся дисках (хочу задействова все что есть)
```
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@lvm vagrant]# pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
```

```
[root@lvm vagrant]# vgcreate VolGroupOPT /dev/sdb /dev/sdc
  Volume group "VolGroupOPT" successfully created
```

```
[root@lvm vagrant]# lvcreate -n LogVolOPT -l +100%FREE /dev/VolGroupOPT
WARNING: xfs signature detected on /dev/VolGroupOPT/LogVolOPT at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroupOPT/LogVolOPT.
  Logical volume "LogVolOPT" created.
```

```
[root@lvm vagrant]# lsblk
NAME                                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                         8:0    0   40G  0 disk
├─sda1                                      8:1    0    1M  0 part
├─sda2                                      8:2    0    1G  0 part /boot
└─sda3                                      8:3    0   39G  0 part
  ├─VolGroup00-LogVolNEW                  253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01                   253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVolNewHOME              253:2    0  512M  0 lvm  /home
sdb                                         8:16   0   10G  0 disk
└─VolGroupOPT-LogVolOPT                   253:8    0   12G  0 lvm
sdc                                         8:32   0    2G  0 disk
└─VolGroupOPT-LogVolOPT                   253:8    0   12G  0 lvm
sdd                                         8:48   0    1G  0 disk
├─VolGroupVAR-LogVolNewVarMirror_rmeta_0  253:3    0    4M  0 lvm
│ └─VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
└─VolGroupVAR-LogVolNewVarMirror_rimage_0 253:4    0  816M  0 lvm
  └─VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
sde                                         8:64   0    1G  0 disk
├─VolGroupVAR-LogVolNewVarMirror_rmeta_1  253:5    0    4M  0 lvm
│ └─VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
└─VolGroupVAR-LogVolNewVarMirror_rimage_1 253:6    0  816M  0 lvm
  └─VolGroupVAR-LogVolNewVarMirror        253:7    0  816M  0 lvm  /var
```

###### Создаем новый пул из lvm раздела, на котором будут размещены виртуальные диски
```
[root@lvm vagrant]# zpool create -f ZFSpool /dev/mapper/VolGroupOPT-LogVolOPT
```

###### Проверяем
```
[root@lvm vagrant]# zpool status
  pool: ZFSpool
 state: ONLINE
  scan: none requested
config:

        NAME                     STATE     READ WRITE CKSUM
        ZFSpool                  ONLINE       0     0     0
          VolGroupOPT-LogVolOPT  ONLINE       0     0     0

errors: No known data errors
```

```
[root@lvm vagrant]# zpool list
NAME      SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
ZFSpool  11.9G   273K  11.9G         -     0%     0%  1.00x  ONLINE  -
```

###### Создаем файловую систему на только что созданном пуле
```
[root@lvm vagrant]# zfs create ZFSpool/opt
```

```
[root@lvm vagrant]# zfs list
NAME          USED  AVAIL  REFER  MOUNTPOINT
ZFSpool       108K  11.6G    24K  /ZFSpool
ZFSpool/opt    24K  11.6G    24K  /ZFSpool/opt
```

###### _Точка монтирования для пула и для каждой созданной в нем файловой системы создается в корневом каталоге_
```
[root@lvm ZFSpool]# zfs mount
ZFSpool                         /ZFSpool
ZFSpool/opt                     /ZFSpool/opt
```

###### Переношу /opt на /ZFSpool/opt
```
zfs umount /ZFSpool/opt
```

```
[root@lvm opt]# zfs set mountpoint=/opt ZFSpool/opt
[root@lvm opt]# zfs get mountpoint ZFSpool/opt
NAME         PROPERTY    VALUE       SOURCE
ZFSpool/opt  mountpoint  /opt        local
```

###### Перезагружаюсь и проверяю монитрование
```
[root@lvm opt]# mount | grep /opt
ZFSpool/opt on /opt type zfs (rw,xattr,noacl)
```

###### Генерируем файлы
```
touch /opt/optfile{1..30}
```

###### Создаем снапшоты средствами zfs
```
zfs snapshot ZFSpool/opt@optbackupsnap
```

###### Проверяем
```
[root@lvm opt]# zfs list -t snapshot
NAME                        USED  AVAIL  REFER  MOUNTPOINT
ZFSpool/opt@optbackupsnap     0B      -    25K  -
```

###### Пробуем откаться после удаления
```
[root@lvm opt]# ls
optfile1   optfile11  optfile13  optfile15  optfile17  optfile19  optfile20  optfile22  optfile24  optfile26  optfile28  optfile3   optfile4  optfile6  optfile8 optfile10  optfile12  optfile14  optfile16  optfile18  optfile2   optfile21  optfile23  optfile25  optfile27  optfile29  optfile30  optfile5  optfile7  optfile9
```

```
[root@lvm opt]# rm -f /opt/optfile{21..29}
[root@lvm opt]# ls
optfile1   optfile11  optfile13  optfile15  optfile17  optfile19  optfile20  optfile30  optfile5  optfile7  optfile9 optfile10  optfile12  optfile14  optfile16  optfile18  optfile2   optfile3   optfile4   optfile6  optfile8
```

```
[root@lvm opt]# zfs list -t snapshot
NAME                        USED  AVAIL  REFER  MOUNTPOINT
ZFSpool/opt@optbackupsnap    15K      -    25K  -
```

###### Откат
```
[root@lvm opt]# zfs rollback ZFSpool/opt@optbackupsnap
[root@lvm opt]# ls
optfile1   optfile11  optfile13  optfile15  optfile17  optfile19  optfile20  optfile22  optfile24  optfile26  optfile28  optfile3   optfile4  optfile6  optfile8 optfile10  optfile12  optfile14  optfile16  optfile18  optfile2   optfile21  optfile23  optfile25  optfile27  optfile29  optfile30  optfile5  optfile7  optfile9
```

#### Файлы успешно восстановлены средствами снапшота зфс

###### Для себя
###### _When trying to cache the read operations, our objective changes. Instead of making sure that we get good performance, as well as reliable transactions, now ZFS’ motive shifts to predicting the future. This means, caching the information that an application would require in the near future, while discarding the ones that will be needed furthest ahead in time._
###### _To do this a part of main memory is used for caching data that was either used recently or the data is being accessed most frequently. That’s where the term Adaptive Replacement Cache (ARC) comes from. In addition to traditional read caching, where only the most recently used objects are cached, the ARC also pays attention to how often the data has been accessed._
###### _L2ARC, or Level 2 ARC, is an extension to the ARC. If you have a dedicated storage device to act as your L2ARC, it will store all the data that is not too important to stay in the ARC but at the same time that data is useful enough to merit a place in the slower-than-memory NVMe device._

#### Пробую поиграться с кэшем, попробую перенести l2arc кэш на раздел lvm в sda3 (представим что это супер пупер быстрый ssd)
```
[root@lvm opt]# lvcreate -n LogVolOPTcache -L 4G /dev/VolGroup00
  Logical volume "LogVolOPTcache" created.
[root@lvm opt]# fdisk -l | grep LogVolOPTcache
Disk /dev/mapper/VolGroup00-LogVolOPTcache: 4294 MB, 4294967296 bytes, 8388608 sectors
```

###### Назначаем кэш
```
zpool add -f ZFSpool cache /dev/mapper/VolGroup00-LogVolOPTcache
```

###### Посмотрим информацию о пуле
```
zpool iostat -v ZFSpool
```

```
[root@lvm opt]# zpool iostat -v ZFSpool
                               capacity     operations     bandwidth
pool                         alloc   free   read  write   read  write
---------------------------  -----  -----  -----  -----  -----  -----
ZFSpool                       197K  11.9G      0      0    940  1.62K
  VolGroupOPT-LogVolOPT       197K  11.9G      0      0    940  1.62K
cache                            -      -      -      -      -      -
  VolGroup00-LogVolOPTcache     2K  4.00G      0      0  4.59K    916
---------------------------  -----  -----  -----  -----  -----  -----
```

###### Вроде всё...
