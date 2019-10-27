Испытания происходили по следующей схеме:

Сервер A (vm/vmware, Debian 10.x, IP: 192.168.100.18) - источник + netem eth 

https://www.excentis.com/blog/use-linux-traffic-control-impairment-node-test-environment-part-2

Сервер A (vm/vmware, Debian 10.x, IP: 192.168.100.19) - получатель, там где управляющий скрипт

На обоих серверах установлен tgvoipcall, parser.py (без аргументов), start.sh

В скрипте задаются иcпытания (packet loss, delay+jitter ...) и их количество.

Результат упаковывается в архив.

Обработка производится offline.

