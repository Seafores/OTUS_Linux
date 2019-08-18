!#/bin/bash

# С какой строки начинаем читать файл access.log
startlong=$(cat /opt/long)
# It's a trap
lockfile=/opt/lockfile
#Старая дата (дату могу вытащить с помощью awk и sed (убрать лишние символы для вывода) через лог, но решил пойти таким путем)
olddate=$(cat /opt/date)
# Конечное положение последней строки
endlong=$(wc /opt/access.log | awk '{print $1}')

if [ $startlong -lt $endlong ]
then
	if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
	then
		trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
		# Очищаем файл перед заполнением
		> /opt/send
		date +%d-%m-%Y\ %H:%M:%S > /opt/date
		newdate=$(cat /opt/date)
		echo -e "Обрабатываемый временной диапазон $olddate - $newdate \n" >> /opt/send
		echo -e "IP адреса с наибольшим кол-вом запросов c момента последнего отчета:" >> /opt/send
		awk '(NR > "$startlong")' /opt/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 >> /opt/send
		echo -e "\nАдреса с наибольшим кол-вом запросов с момента последнего отчета:" >> /opt/send
		awk '(NR > "$startlong")' /opt/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 10 >> /opt/send
		echo -e "\nВсе ошибки c момента последнего запуска:" >> /opt/send
		awk '(NR > "$startlong")' /opt/access.log | awk '{if ($9 ~ /4../) print $9}' | sort | uniq -c | sort -rn | grep -Ev "-" >> /opt/send
		echo -e "\nCписок всех кодов возврата с момента последнего отчета:" >> /opt/send
		awk '(NR > "$startlong")' /opt/access.log | awk '{print $9}' | sort | uniq -c | sort -rn | grep -Ev "-" >> /opt/send
		echo $endlong > /opt/long
		# Отправляем отчет на root
		cat /opt/send | sendmail -v root@localhost
		rm -f "$lockfile"
		trap - INT TERM EXIT
	fi
else
	# Очищаем файл перед заполнением
	> /opt/send
	date +%d-%m-%Y\ %H:%M:%S > /opt/date
	newdate=$(cat /opt/date)
	echo -e "За временной диапазон $olddate - $newdate изменений в access.log не происходило" >> /opt/send
	# Отправляем отчет на root
	cat /opt/send | sendmail -v root@localhost
fi
