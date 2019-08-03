#!/usr/bin/env bash

# На всякий случай
mdadm --zero-superblock --force /dev/sd{b,c}

# Создаем RAID1 из двух дисков (sdb, sdc)
mdadm --create --verbose /dev/md1 --level=1 --raid-devices=2 /dev/sdb /dev/sdc --metadata=0.90

# Создание конфигурационного файла mdadm.conf
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
