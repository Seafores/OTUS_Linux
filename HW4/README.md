# Домашнее задание 4 (OTUS Linux 2019 - 07)

###### написать скрипт для крона
###### который раз в час присылает на заданную почту
###### - X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
###### - Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
###### - все ошибки c момента последнего запуска
###### - список всех кодов возврата с указанием их кол-ва с момента последнего запуска
###### в письме должно быть прописан обрабатываемый временной диапазон
###### должна быть реализована защита от мультизапуска
###### Критерии оценки:
###### трапы и функции, а также sed и find +1 балл 

---

#### Перед написанием скрипта для cron отработаю все основные моменты по одиночке (для себя)

###### Для начала разберем содержимое access.log (для себя)

###### _Формат логов, который используется в nginx по умолчанию:_
###### _$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"_

###### _Где:_
###### _$remote_addr 		– IP с которого был сделан запрос_
###### _$remote_user 		– Пользователь, аутентифицированный через HTTP аутентификацию, обычно пустое_
###### _[$time_local] 		– Время посещения в часовом поясе сервера_
###### _"$request" 		- Тип HTTP-запроса + запрошенный путь без аргументов + версия HTTP_
###### _$status 		- код ответа от сервера_
###### _$body_bytes_sent 	- размер ответа сервера в байтах_
###### _"$http_referer" 	- реферал (если есть)_
###### _"$http_user_agent" 	- юзер-агент_
###### 
###### _200.33.155.30 - - [14/Aug/2019:04:12:10 +0300] "GET / HTTP/1.1" 200 3698 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.7 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.7"rt=0.000 uct="-" uht="-" urt="-"_

###### Разобьем лог по столбцам (для ДЗ4 нужны только первые 9-10, разделитель пробел):
###### 1) 200.33.155.30 		- IP с которого был сделан запрос
###### 2) -				- Пользователь, аутентифицированный через HTTP аутентификацию
###### 3) -				- ХЗ
###### 4) [14/Aug/2019:04:12:10	- Время посещения 
###### 5) +0300]			- Часовой пояс
###### 6) "GET				- Тип HTTP-запроса
###### 7) /				- Запрошенный путь без аргументов
###### 8) HTTP/1.1"			- Версия HTTP
###### 9) 200				- Код ответа от сервера (https://ru.wikipedia.org/wiki/Список_кодов_состояния_HTTP)
###### 10) 3698			- Размер ответа сервера в байтах

###### ДЗ4Ч1: X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта

###### Для сортировки воспользуемся awk (выводим первые ТОП 10)
```
awk '{print $1}' 3.log | sort | uniq -c | sort -rn | head -n 10
```

##### ДЗ4Ч2: Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта

###### Для сортировки воспользуемся так же awk (выводим первые ТОП 10)
```
awk '{print $7}' 3.log | sort | uniq -c | sort -rn | head -n 10
```

##### ДЗ4Ч3: Все ошибки c момента последнего запуска
###### Выводим всё одной командой, сортировку задал как 4.. (ошибки начинаются всегда с цифры 4 и имеют трехзначный код, выводим первые ТОП 10):
```
awk '($9 ~ /4../)' 3.log | awk '{print $9}' | sort | uniq -c | sort -rn
```

##### ДЗ4Ч4: Cписок всех кодов возврата с указанием их кол-ва с момента последнего запуска
###### Для сортировки воспользуемся так же awk (выводим первые ТОП 10)
```
awk '{print $7}' 3.log | sort | uniq -c | sort -rn | head -n 10
```

###### Комментарий для себя: функции, find и sed использовать не буду, для выполнения задачи не пригодятся.

###### Использовать awk с 660 строки
```
awk '(NR > 660)' 3.log | awk '{print $1}' | sort | uniq -c | sort -rn
```

###### Создаем файл где будут храниться строки
```
[root@KernelVM opt]# touch /opt/long
[root@KernelVM opt]# echo 0 > /opt/long
```

###### Начальное положение строки
```
[root@KernelVM opt]# startlong=$(cat /opt/long)
[root@KernelVM opt]# echo $startlong
0
```

###### Конечное положение последней строки
```
[root@KernelVM vagrant]# endlong=$(wc /vagrant/3.log | awk '{print $1}')
[root@KernelVM vagrant]# echo $endlong
669
```

###### Установим утилиту для отправки сообщений
```
yum install mailx -y
```

###### Проверяем работу trap
```
[root@KernelVM opt]# ./script.sh
-rw-r--r--. 1 root root 5 Aug 16 18:47 /opt/lockfile
```

###### Во втором окне пробую запустить скрипт повторно
```
[root@KernelVM opt]# ./script.sh
Failed to acquire lockfile: /opt/lockfile.
Held by 3814
```

###### Поигрался с Kill -s 15 3814, работает корректно.

###### Команды для работы с внутренней почтой
```
echo "test" | mail -s "Subject" root@localhost
echo "test" |sendmail -v root@localhost
```

###### Создадим файл с текущей датой, необходим по условиям ДЗ для указания периода сработки скрипта
```
[root@KernelVM vagrant]# date +%d-%m-%Y\ %H:%M:%S > /opt/date
[root@KernelVM vagrant]# cat /opt/date
16-08-2019 19:32:05
```

###### Всё что нужно для скрипта есть, делаем [script.sh](script.sh)

###### Поправили [cron](crontab), для теста запускам скрипт каждую минуту. После каждой сработки я вручную буду его наполнять access.log (разбил до этого лог на 3 части по возрастанию).

###### Проверка работы скрипта будет проводиться подменой access.log после анализа предыдущего лога (на скорую руку ничего более не придумал)
```
[root@KernelVM mail]# cd /vagrant
[root@KernelVM vagrant]# ls
1.log  2.log  3.log  Vagrantfile
[root@KernelVM vagrant]# wc 1.log 2.log 3.log
   218   4799  55207 1.log
   407   9069 104788 2.log
   669  14442 166554 3.log
```

###### Перезапускаем cron и ждем выполнения скрипта
```
[root@KernelVM vagrant]# echo 0 > /opt/long

[root@KernelVM mail]# wc /var/mail/root
wc: /var/mail/root: No such file or directory

[root@KernelVM vagrant]# wc /var/mail/root
 110  320 3680 /var/mail/root
[root@KernelVM vagrant]# mv /vagrant/2.log /opt/access.log -f

[root@KernelVM mail]# wc /var/mail/root
 274  824 9358 /var/mail/root
[root@KernelVM mail]# mv /vagrant/3.log /opt/access.log -f

[root@KernelVM mail]# wc /var/mail/root
  387  1150 13015 /var/mail/root
```

###### Проверям сработку скрипта прочитав файл [/var/mail/root](mail.log)

#### На этом ДЗ4 считаю выполненым.
