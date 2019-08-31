#### Работа с загрузчиком
#### Цель: Зайти в систему без пароля рута - базовая задача сисадмина ( ну и одно из заданий на любой линуксовой сертификации). Так же нужно уметь управлять поведением загрузчика. Это и будем учиться делать в ДЗ
#### 1. Попасть в систему без пароля несколькими способами
#### 2. Установить систему с LVM, после чего переименовать VG
#### 3. Добавить модуль в initrd
#### 4(*). Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
#### Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
#### PV необходимо инициализировать с параметром --bootloaderareasize 1m

---

##### Получил доступ к системе двумя способами. Первый способ - использование командной строки при загрузке в grub. Попробовал на системе Debian.
##### 1) Перезагрузил ВМ, в Grub2 при окне выбора ядра (на скриншоте *Debian GNU/Linux) нажал "е"
##### 2) В конце строки, начинающийся с "linux /boot/vmlinuz-...", дописал init=/bin/bash
##### 3) Нажал ctrl+x, подгрузилась система
##### 4) Была примонтирована корневая файловая система с правами на запись командой "mount -rw -o remount /"
##### 5) Командой passwd поменял пароль на root
##### 6) Проверил
##### 
##### Второй способ с использованием Live CD. Использовал Live CD Debian, на Centos 7
##### 1) Командой lsblk определил на каком разделе стоит ОС
##### 2) Смонтировал раздел в /mnt
##### 3) chroot /mnt
##### 4) Командой passwd сменил пароль на root
##### 
##### Есть следующий способ для сброса пароля для CentOS 7:
##### 1) В меню загрузки нажимаем «e»
##### 2) В строке linux16 заменяем "ro" на "rw init=/sysroot/bin/sh", далее Ctrl + X
##### 3) Последней командой мы попадаем в emergency режим, выполняем команду "chroot /sysroot"
##### 4) Сбрасываем пароль командой "passwd root"
##### 5) После этого, обновляем параметры SELinux командой "touch /.autorelabel", перезагружаемся
##### 
##### Так же есть другие способы, например с использованием команд "rd.break init=/bin/bash", "systemd.unit=emergency.target" или "rd.break enforcing=0". Но при использовании этих команд, моя ВМ подвисала и не доходила до нужного режима, поэтому я провел восстановление пароля root через Grub2 в ОС Debian (думаю в рамказ ДЗ это не критично).
##### 
##### Прилагаю скриншоты из окна Virtualbox:
- [1 CentOS Live 1.jpg](CentOS Live 1.jpg)
- [2 CentOS Live 2.jpg](CentOS Live 2.jpg)
- [3 Debian 1.jpg](https://github.com/Seafores/OTUS_Linux/blob/master/HW7/Debian%201.jpg)
- [4 Debian 2.jpg](Debian 2.jpg)
- [5 Debian 3.jpg](Debian 3.jpg)
- [6 Debian 4.jpg](Debian 4.jpg)
- [7 Debian 5.jpg](Debian 5.jpg)

---

##### Приступаю к 2 пункту ДЗ. Использовал Vagrantfile, с готовым LVM (версия бокса 1804.02).
##### Смотрим какой LVM присутствует в системе
```
[root@hw7 vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0
```
```
[root@hw7 vagrant]# vgrename --help
  vgrename - Rename a volume group

  Rename a VG.
  vgrename VG VG_new
        [ COMMON_OPTIONS ]

  Rename a VG by specifying the VG UUID.
  vgrename String VG_new
        [ COMMON_OPTIONS ]

  Common options for command:
        [ -A|--autobackup y|n ]
        [ -f|--force ]
        [    --reportformat basic|json ]

  Common options for lvm:
        [ -d|--debug ]
        [ -h|--help ]
        [ -q|--quiet ]
        [ -v|--verbose ]
        [ -y|--yes ]
        [ -t|--test ]
        [    --commandprofile String ]
        [    --config String ]
        [    --driverloaded y|n ]
        [    --lockopt String ]
        [    --longhelp ]
        [    --profile String ]
        [    --version ]
```

##### Меняем название Volume Group.
```
[root@hw7 vagrant]# vgrename VolGroup00 VG_NewName
  Volume group "VolGroup00" successfully renamed to "VG_NewName"
```

##### Далее необходимо заменить название VG на актуальное в файлах:
##### /etc/fstab
##### /etc/default/grub
##### /boot/grub2/grub.cfg
##### 
##### Выполним это командами:
```
[root@hw7 vagrant]# perl -pi -e 's/VolGroup00/VG_NewName/g' /etc/fstab
[root@hw7 vagrant]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VG_NewName-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VG_NewName-LogVol01 swap                    swap    defaults        0 0
```

```
[root@hw7 vagrant]# perl -pi -e 's/VolGroup00/VG_NewName/g' /etc/default/grub
[root@hw7 vagrant]# cat /etc/default/grub
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG_NewName/LogVol00 rd.lvm.lv=VG_NewName/LogVol01 rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```

```
[root@hw7 vagrant]# perl -pi -e 's/VolGroup00/VG_NewName/g' /boot/grub2/grub.cfg
[root@hw7 vagrant]# cat /boot/grub2/grub.cfg
#
# DO NOT EDIT THIS FILE
#
# It is automatically generated by grub2-mkconfig using templates
# from /etc/grub.d and settings from /etc/default/grub
#

### BEGIN /etc/grub.d/00_header ###
set pager=1

if [ -s $prefix/grubenv ]; then
  load_env
fi
if [ "${next_entry}" ] ; then
   set default="${next_entry}"
   set next_entry=
   save_env next_entry
   set boot_once=true
else
   set default="${saved_entry}"
fi

if [ x"${feature_menuentry_id}" = xy ]; then
  menuentry_id_option="--id"
else
  menuentry_id_option=""
fi

export menuentry_id_option

if [ "${prev_saved_entry}" ]; then
  set saved_entry="${prev_saved_entry}"
  save_env saved_entry
  set prev_saved_entry=
  save_env prev_saved_entry
  set boot_once=true
fi

function savedefault {
  if [ -z "${boot_once}" ]; then
    saved_entry="${chosen}"
    save_env saved_entry
  fi
}

function load_video {
  if [ x$feature_all_video_module = xy ]; then
    insmod all_video
  else
    insmod efi_gop
    insmod efi_uga
    insmod ieee1275_fb
    insmod vbe
    insmod vga
    insmod video_bochs
    insmod video_cirrus
  fi
}

terminal_output console
if [ x$feature_timeout_style = xy ] ; then
  set timeout_style=menu
  set timeout=1
# Fallback normal timeout code in case the timeout_style feature is
# unavailable.
else
  set timeout=1
fi
### END /etc/grub.d/00_header ###

### BEGIN /etc/grub.d/00_tuned ###
set tuned_params=""
set tuned_initrd=""
### END /etc/grub.d/00_tuned ###

### BEGIN /etc/grub.d/01_users ###
if [ -f ${prefix}/user.cfg ]; then
  source ${prefix}/user.cfg
  if [ -n "${GRUB2_PASSWORD}" ]; then
    set superusers="root"
    export superusers
    password_pbkdf2 root ${GRUB2_PASSWORD}
  fi
fi
### END /etc/grub.d/01_users ###

### BEGIN /etc/grub.d/10_linux ###
menuentry 'CentOS Linux (3.10.0-957.27.2.el7.x86_64) 7 (Core)' --class centos --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-862.2.3.el7.x86_64-advanced-b60e9498-0baa-4d9f-90aa-069048217fee' {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod xfs
        set root='hd0,msdos2'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint='hd0,msdos2'  570897ca-e759-4c81-90cf-389da6eee4cc
        else
          search --no-floppy --fs-uuid --set=root 570897ca-e759-4c81-90cf-389da6eee4cc
        fi
        linux16 /vmlinuz-3.10.0-957.27.2.el7.x86_64 root=/dev/mapper/VG_NewName-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG_NewName/LogVol00 rd.lvm.lv=VG_NewName/LogVol01 rhgb quiet LANG=en_US.UTF-8
        initrd16 /initramfs-3.10.0-957.27.2.el7.x86_64.img
}
menuentry 'CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)' --class centos --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-862.2.3.el7.x86_64-advanced-b60e9498-0baa-4d9f-90aa-069048217fee' {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod xfs
        set root='hd0,msdos2'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint='hd0,msdos2'  570897ca-e759-4c81-90cf-389da6eee4cc
        else
          search --no-floppy --fs-uuid --set=root 570897ca-e759-4c81-90cf-389da6eee4cc
        fi
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VG_NewName-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG_NewName/LogVol00 rd.lvm.lv=VG_NewName/LogVol01 rhgb quiet
        initrd16 /initramfs-3.10.0-862.2.3.el7.x86_64.img
}
if [ "x$default" = 'CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)' ]; then default='Advanced options for CentOS Linux>CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)'; fi;
### END /etc/grub.d/10_linux ###

### BEGIN /etc/grub.d/20_linux_xen ###
### END /etc/grub.d/20_linux_xen ###

### BEGIN /etc/grub.d/20_ppc_terminfo ###
### END /etc/grub.d/20_ppc_terminfo ###

### BEGIN /etc/grub.d/30_os-prober ###
### END /etc/grub.d/30_os-prober ###

### BEGIN /etc/grub.d/40_custom ###
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
### END /etc/grub.d/40_custom ###

### BEGIN /etc/grub.d/41_custom ###
if [ -f  ${config_directory}/custom.cfg ]; then
  source ${config_directory}/custom.cfg
elif [ -z "${config_directory}" -a -f  $prefix/custom.cfg ]; then
  source $prefix/custom.cfg;
fi
### END /etc/grub.d/41_custom ###
```

##### Обновляем initramfs, чтобы подтянулось новое название VG
```
[root@hw7 vagrant]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
Executing: /sbin/dracut -f -v /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
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
##### Перезагружаемся и проверям
```
[root@hw7 vagrant]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

F:\Vagrant>Vagrant ssh
Last login: Sat Aug 31 07:26:36 2019 from 10.0.2.2

[vagrant@hw7 ~]$ sudo su
[root@hw7 vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VG_NewName   1   2   0 wz--n- <38.97g    0
```
---

##### Приступаю к 3 части ДЗ. Создаем каталог для своего модуля.
```
[root@hw7 modules.d]# mkdir /usr/lib/dracut/modules.d/01test
```

##### Дополняем папку двумя скриптами (для установки, и сам модуль):
```
[root@hw7 01test]# nano module-setup.sh
[root@hw7 01test]# nano test.sh
[root@hw7 01test]# cat module-setup.sh
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
```

```
[root@hw7 01test]# cat test.sh
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'

Hello! You are in dracut module!

 ___________________
< Luke, I Am Your Father>
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo "continuing...."
```

##### Пересобираем образ initrd
```
[root@hw7 01test]# dracut -f -v
Executing: /sbin/dracut -f -v
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: test ***
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
*** Creating initramfs image file '/boot/initramfs-3.10.0-957.27.2.el7.x86_64.img' done ***
```

##### Проверяем подтянулся ли профиль test
```
[root@hw7 01test]# lsinitrd -m /boot/initramfs-$(uname -r).img
Image: /boot/initramfs-3.10.0-957.27.2.el7.x86_64.img: 15M
========================================================================
Version: dracut-033-554.el7

dracut modules:
bash
test
nss-softokn
i18n
drm
plymouth
dm
kernel-modules
lvm
qemu
resume
rootfs-block
terminfo
udev-rules
biosdevname
systemd
usrmount
base
fs-lib
shutdown
========================================================================
```

##### Модуль подгружен. Чтобы увидеть сообщение правим grub (убираем из строки linux16...):
```
[root@hw7 01test]# cd /
[root@hw7 /]# whereis grub.cfg
grub: /usr/lib/grub /etc/grub.d /etc/grub2.cfg /usr/share/grub
[root@hw7 /]# nano /etc/grub2.cfg
[root@hw7 /]# cat /etc/grub2.cfg
#
# DO NOT EDIT THIS FILE
#
# It is automatically generated by grub2-mkconfig using templates
# from /etc/grub.d and settings from /etc/default/grub
#

### BEGIN /etc/grub.d/00_header ###
set pager=1

if [ -s $prefix/grubenv ]; then
  load_env
fi
if [ "${next_entry}" ] ; then
   set default="${next_entry}"
   set next_entry=
   save_env next_entry
   set boot_once=true
else
   set default="${saved_entry}"
fi

if [ x"${feature_menuentry_id}" = xy ]; then
  menuentry_id_option="--id"
else
  menuentry_id_option=""
fi

export menuentry_id_option

if [ "${prev_saved_entry}" ]; then
  set saved_entry="${prev_saved_entry}"
  save_env saved_entry
  set prev_saved_entry=
  save_env prev_saved_entry
  set boot_once=true
fi

function savedefault {
  if [ -z "${boot_once}" ]; then
    saved_entry="${chosen}"
    save_env saved_entry
  fi
}

function load_video {
  if [ x$feature_all_video_module = xy ]; then
    insmod all_video
  else
    insmod efi_gop
    insmod efi_uga
    insmod ieee1275_fb
    insmod vbe
    insmod vga
    insmod video_bochs
    insmod video_cirrus
  fi
}

terminal_output console
if [ x$feature_timeout_style = xy ] ; then
  set timeout_style=menu
  set timeout=1
# Fallback normal timeout code in case the timeout_style feature is
# unavailable.
else
  set timeout=1
fi
### END /etc/grub.d/00_header ###

### BEGIN /etc/grub.d/00_tuned ###
set tuned_params=""
set tuned_initrd=""
### END /etc/grub.d/00_tuned ###

### BEGIN /etc/grub.d/01_users ###
if [ -f ${prefix}/user.cfg ]; then
  source ${prefix}/user.cfg
  if [ -n "${GRUB2_PASSWORD}" ]; then
    set superusers="root"
    export superusers
    password_pbkdf2 root ${GRUB2_PASSWORD}
  fi
fi
### END /etc/grub.d/01_users ###

### BEGIN /etc/grub.d/10_linux ###
menuentry 'CentOS Linux (3.10.0-957.27.2.el7.x86_64) 7 (Core)' --class centos --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-862.2.3.el7.x86_64-advanced-b60e9498-0baa-4d9f-90aa-069048217fee' {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod xfs
        set root='hd0,msdos2'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint='hd0,msdos2'  570897ca-e759-4c81-90cf-389da6eee4cc
        else
          search --no-floppy --fs-uuid --set=root 570897ca-e759-4c81-90cf-389da6eee4cc
        fi
        linux16 /vmlinuz-3.10.0-957.27.2.el7.x86_64 root=/dev/mapper/VG_NewName-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG_NewName/LogVol00 rd.lvm.lv=VG_NewName/LogVol01 rhgb quiet LANG=en_US.UTF-8
        initrd16 /initramfs-3.10.0-957.27.2.el7.x86_64.img
}
menuentry 'CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)' --class centos --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-862.2.3.el7.x86_64-advanced-b60e9498-0baa-4d9f-90aa-069048217fee' {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod xfs
        set root='hd0,msdos2'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint='hd0,msdos2'  570897ca-e759-4c81-90cf-389da6eee4cc
        else
          search --no-floppy --fs-uuid --set=root 570897ca-e759-4c81-90cf-389da6eee4cc
        fi
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VG_NewName-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG_NewName/LogVol00 rd.lvm.lv=VG_NewName/LogVol01
        initrd16 /initramfs-3.10.0-862.2.3.el7.x86_64.img
}
if [ "x$default" = 'CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)' ]; then default='Advanced options for CentOS Linux>CentOS Linux (3.10.0-862.2.3.el7.x86_64) 7 (Core)'; fi;
### END /etc/grub.d/10_linux ###

### BEGIN /etc/grub.d/20_linux_xen ###
### END /etc/grub.d/20_linux_xen ###

### BEGIN /etc/grub.d/20_ppc_terminfo ###
### END /etc/grub.d/20_ppc_terminfo ###

### BEGIN /etc/grub.d/30_os-prober ###
### END /etc/grub.d/30_os-prober ###

### BEGIN /etc/grub.d/40_custom ###
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
### END /etc/grub.d/40_custom ###

### BEGIN /etc/grub.d/41_custom ###
if [ -f  ${config_directory}/custom.cfg ]; then
  source ${config_directory}/custom.cfg
elif [ -z "${config_directory}" -a -f  $prefix/custom.cfg ]; then
  source $prefix/custom.cfg;
fi
### END /etc/grub.d/41_custom ###
```

##### Перезагружаемся, смотрим на [пингвина](Pinguin.jpg).

---

##### Приступаем к заданию со звездой (Переустановил VM, в Vagrantfile добавил HDD).

##### Смотрим какие разделы у нас есть
```
[root@hw7 vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
```
##### Видим что boot находится на отдельном разделе sda2, корень и swap на VG.

##### Установим пропатченный grub2^
```
[root@hw7 vagrant]# yum-config-manager --add-repo=https://yum.rumyantsev.com/centos/7/x86_64/
Loaded plugins: fastestmirror
adding repo from: https://yum.rumyantsev.com/centos/7/x86_64/

[yum.rumyantsev.com_centos_7_x86_64_]
name=added from: https://yum.rumyantsev.com/centos/7/x86_64/
baseurl=https://yum.rumyantsev.com/centos/7/x86_64/
enabled=1
```

```
[root@hw7 vagrant]# yum update -y --nogpgcheck
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.sale-dedic.com
 * extras: mirror.sale-dedic.com
 * updates: mirror.linux-ia64.org
Resolving Dependencies
--> Running transaction check
---> Package grub2.x86_64 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2.x86_64 2:2.02-0.76.el7 will be an update
---> Package grub2-common.noarch 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-common.noarch 2:2.02-0.76.el7 will be an update
---> Package grub2-pc.x86_64 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-pc.x86_64 2:2.02-0.76.el7 will be an update
---> Package grub2-pc-modules.noarch 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-pc-modules.noarch 2:2.02-0.76.el7 will be an update
---> Package grub2-tools.x86_64 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-tools.x86_64 2:2.02-0.76.el7 will be an update
---> Package grub2-tools-extra.x86_64 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-tools-extra.x86_64 2:2.02-0.76.el7 will be an update
---> Package grub2-tools-minimal.x86_64 1:2.02-0.76.el7.centos.1 will be updated
---> Package grub2-tools-minimal.x86_64 2:2.02-0.76.el7 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

============================================================================================================================================================================
 Package                                  Arch                        Version                                Repository                                                Size
============================================================================================================================================================================
Updating:
 grub2                                    x86_64                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                       29 k
 grub2-common                             noarch                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                      727 k
 grub2-pc                                 x86_64                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                       29 k
 grub2-pc-modules                         noarch                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                      845 k
 grub2-tools                              x86_64                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                      1.8 M
 grub2-tools-extra                        x86_64                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                      998 k
 grub2-tools-minimal                      x86_64                      2:2.02-0.76.el7                        yum.rumyantsev.com_centos_7_x86_64_                      171 k

Transaction Summary
============================================================================================================================================================================
Upgrade  7 Packages

Total size: 4.5 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : 2:grub2-common-2.02-0.76.el7.noarch                                                                                                                     1/14
  Updating   : 2:grub2-tools-minimal-2.02-0.76.el7.x86_64                                                                                                              2/14
  Updating   : 2:grub2-tools-2.02-0.76.el7.x86_64                                                                                                                      3/14
  Updating   : 2:grub2-tools-extra-2.02-0.76.el7.x86_64                                                                                                                4/14
  Updating   : 2:grub2-pc-modules-2.02-0.76.el7.noarch                                                                                                                 5/14
  Updating   : 2:grub2-pc-2.02-0.76.el7.x86_64                                                                                                                         6/14
  Updating   : 2:grub2-2.02-0.76.el7.x86_64                                                                                                                            7/14
  Cleanup    : 1:grub2-2.02-0.76.el7.centos.1.x86_64                                                                                                                   8/14
  Cleanup    : 1:grub2-pc-2.02-0.76.el7.centos.1.x86_64                                                                                                                9/14
  Cleanup    : 1:grub2-tools-extra-2.02-0.76.el7.centos.1.x86_64                                                                                                      10/14
  Cleanup    : 1:grub2-pc-modules-2.02-0.76.el7.centos.1.noarch                                                                                                       11/14
  Cleanup    : 1:grub2-tools-2.02-0.76.el7.centos.1.x86_64                                                                                                            12/14
  Cleanup    : 1:grub2-tools-minimal-2.02-0.76.el7.centos.1.x86_64                                                                                                    13/14
  Cleanup    : 1:grub2-common-2.02-0.76.el7.centos.1.noarch                                                                                                           14/14
  Verifying  : 2:grub2-pc-2.02-0.76.el7.x86_64                                                                                                                         1/14
  Verifying  : 2:grub2-common-2.02-0.76.el7.noarch                                                                                                                     2/14
  Verifying  : 2:grub2-tools-extra-2.02-0.76.el7.x86_64                                                                                                                3/14
  Verifying  : 2:grub2-pc-modules-2.02-0.76.el7.noarch                                                                                                                 4/14
  Verifying  : 2:grub2-tools-minimal-2.02-0.76.el7.x86_64                                                                                                              5/14
  Verifying  : 2:grub2-tools-2.02-0.76.el7.x86_64                                                                                                                      6/14
  Verifying  : 2:grub2-2.02-0.76.el7.x86_64                                                                                                                            7/14
  Verifying  : 1:grub2-tools-extra-2.02-0.76.el7.centos.1.x86_64                                                                                                       8/14
  Verifying  : 1:grub2-common-2.02-0.76.el7.centos.1.noarch                                                                                                            9/14
  Verifying  : 1:grub2-tools-2.02-0.76.el7.centos.1.x86_64                                                                                                            10/14
  Verifying  : 1:grub2-2.02-0.76.el7.centos.1.x86_64                                                                                                                  11/14
  Verifying  : 1:grub2-pc-modules-2.02-0.76.el7.centos.1.noarch                                                                                                       12/14
  Verifying  : 1:grub2-tools-minimal-2.02-0.76.el7.centos.1.x86_64                                                                                                    13/14
  Verifying  : 1:grub2-pc-2.02-0.76.el7.centos.1.x86_64                                                                                                               14/14

Updated:
  grub2.x86_64 2:2.02-0.76.el7          grub2-common.noarch 2:2.02-0.76.el7         grub2-pc.x86_64 2:2.02-0.76.el7               grub2-pc-modules.noarch 2:2.02-0.76.el7
  grub2-tools.x86_64 2:2.02-0.76.el7    grub2-tools-extra.x86_64 2:2.02-0.76.el7    grub2-tools-minimal.x86_64 2:2.02-0.76.el7

Complete!
```

##### Смотрю названия дисков в системе
```
[root@hw7 vagrant]# fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000b47f7

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1            2048        4095        1024   83  Linux
/dev/sda2   *        4096     2101247     1048576   83  Linux
/dev/sda3         2101248    83886079    40892416   8e  Linux LVM

Disk /dev/sdb: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/VolGroup00-LogVol00: 40.2 GB, 40231763968 bytes, 78577664 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/VolGroup00-LogVol01: 1610 MB, 1610612736 bytes, 3145728 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

##### Т.к. нет желания уменьшать первый LVM раздел для переноса boot, пожертвуем свопом. Незнаю как отмонтировать swap, поэтому правим fstab и перезагружаемся чтобы он отмонтировался.
```
[root@hw7 vagrant]# nano /etc/fstab
[root@hw7 vagrant]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
#/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0

[root@hw7 vagrant]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
```

##### Проверяем
```
F:\Vagrant>Vagrant ssh
Last login: Sat Aug 31 10:14:15 2019 from 10.0.2.2
Last login: Sat Aug 31 10:14:15 2019 from 10.0.2.2
[vagrant@hw7 ~]$ sudo su
[root@hw7 vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm
sdb                       8:16   0   10G  0 disk
                    8:16   0   10G  0 disk
```

##### Форматируем раздел для boot
```
[root@hw7 vagrant]# mkfs.ext2 /dev/mapper/VolGroup00-LogVol01
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
98304 inodes, 393216 blocks
19660 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=402653184
12 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Writing superblocks and filesystem accounting information: done
```

##### Монитруем, и переносим содержимое /boot на lvm
```
[root@hw7 vagrant]# mount /dev/mapper/VolGroup00-LogVol01 /mnt
[root@hw7 vagrant]# cp -r /boot/* /mnt
```

##### Снова правим fstab, удаляю старый boot и прописываю новый который находится на lvm
```
[root@hw7 mnt]# nano /etc/fstab
[root@hw7 mnt]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
#UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 /boot                    ext2    defaults        0 0
```

##### Перезагружаемся и проверям
```
[root@hw7 mnt]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

F:\Vagrant>Vagrant ssh
Last login: Sat Aug 31 10:28:40 2019 from 10.0.2.2
[vagrant@hw7 ~]$ sudo su
[root@hw7 vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  /boot
sdb                       8:16   0   10G  0 disk
```

### На этом этапе boot раздел был перенесен с HDD на LVM.
