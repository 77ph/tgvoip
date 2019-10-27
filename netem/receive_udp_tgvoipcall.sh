#!/bin/bash
DATE=$( date +"%Y-%m-%d" )

#rm -rf sw1*.wav
#timelimit -t 75 -T 90 ffmpeg -i udp://192.168.100.19:1234 sw1-${DATE}.wav > /dev/null 2>&1 &
#ssh root@192.168.100.18 'cd /home/andrey/pyvoip-project/voice && ffmpeg -re -i sw.wav -f mpegts udp://192.168.100.19:1234 > /dev/null 2>&1'

rm -rf *.tgz
rm -rf sw_*.ogg
rm -rf *.txt
rm -rf start_B*

### испытание 1 
#packet_loss


###skipped
for (( i=5 ; $i<35 ; i=(($i+5)) ))
do
        echo "packet loss = $i"
        # set netem
        command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
        command2="sudo /usr/sbin/tc qdisc add dev ens33 root netem delay 10ms loss ${i}%"
        echo ${command1}
        echo ${command2}
        ../tgvoipcall/python/parser.py > /dev/null 2>&1
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python && ./parser.py > start_B.log 2>&1 &'
        ssh andrey@192.168.100.18 "${command1}"
        ssh andrey@192.168.100.18 "${command2}"
        ssh andrey@192.168.100.18 '/usr/sbin/tc qdisc'
        cd /home/andrey/pyvoip-project/tgvoipcall/python/
        ./parser.py > /dev/null 2>&1 
        chmod 755 *.sh
        ./start_B.sh > start_B.log 2>&1 &
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python/ && chmod 755 *.sh && ./start_A.sh'
        pid=$( ps ax | grep tgvoipcall | grep -v grep | grep -v receive_udp_tgvoipcall.sh | awk '{print $1}' )
        echo ${pid}
        while kill -0 ${pid} 2> /dev/null; do sleep 1; done
        sleep 1
        cd ~/pyvoip-project/voice
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A.ogg ./sw_pl_${i}.ogg
        mv /home/andrey/pyvoip-project/tgvoipcall/python/start_B.log ./start_B_pl_${i}.log
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A_out.txt ./sw_pl_${i}_out.txt
        scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/start_A.log ./start_A_pl_${i}.log
        ls -al sw_pl_*.ogg
        ls -al *.txt
        #ffprobe sw_pl_${i}.wav 2>&1 | grep Duration
done

#
#delay + jitter

for (( i=5 ; $i<35 ; i=(($i+5)) ))
do
        echo "delay + jitter = $i"
        # set netem
        command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
        command2="sudo /usr/sbin/tc qdisc add dev ens33 root netem delay 100ms ${i}ms"
        echo ${command1}
        echo ${command2}
        ../tgvoipcall/python/parser.py > /dev/null 2>&1
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python && ./parser.py > /dev/null 2>&1'
        ssh andrey@192.168.100.18 "${command1}"
        ssh andrey@192.168.100.18 "${command2}"
        ssh andrey@192.168.100.18 '/usr/sbin/tc qdisc'
        cd /home/andrey/pyvoip-project/tgvoipcall/python/
        ./parser.py > /dev/null 2>&1 
        chmod 755 *.sh
        ./start_B.sh > start_B.log 2>&1 &
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python/ && chmod 755 *.sh && ./start_A.sh'
        pid=$( ps ax | grep tgvoipcall | grep -v grep | grep -v receive_udp_tgvoipcall.sh | awk '{print $1}' )
        echo ${pid}
        while kill -0 ${pid} 2> /dev/null; do sleep 1; done
        sleep 1
        cd ~/pyvoip-project/voice
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A.ogg ./sw_ji_${i}.ogg    
        mv /home/andrey/pyvoip-project/tgvoipcall/python/start_B.log ./start_B_ji_${i}.log
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A_out.txt ./sw_ji_${i}_out.txt
        scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/start_A.log ./start_A_ji_${i}.log
        ls -al sw_ji_*.ogg
        ls -al *.txt
done

##
#reorder

for (( i=10 ; $i<60 ; i=(($i+10)) ))
do
        echo "reorder = $i"
        # set netem
        command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
        command2="sudo /usr/sbin/tc qdisc add dev ens33 root netem delay 10ms reorder ${i}%"
        echo ${command1}
        echo ${command2}
        ../tgvoipcall/python/parser.py > /dev/null 2>&1
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python && ./parser.py > /dev/null 2>&1'
        ssh andrey@192.168.100.18 "${command1}"
        ssh andrey@192.168.100.18 "${command2}"
        ssh andrey@192.168.100.18 'sudo /usr/sbin/tc qdisc'
        cd /home/andrey/pyvoip-project/tgvoipcall/python/
        ./parser.py > /dev/null 2>&1 
        chmod 755 *.sh
        ./start_B.sh > start_B.log 2>&1 &
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python/ && chmod 755 *.sh && ./start_A.sh'
        pid=$( ps ax | grep tgvoipcall | grep -v grep | grep -v receive_udp_tgvoipcall.sh | awk '{print $1}' )
        echo ${pid}
        while kill -0 ${pid} 2> /dev/null; do sleep 1; done
        sleep 1
        cd ~/pyvoip-project/voice
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A.ogg ./sw_ro_${i}.ogg    
        mv /home/andrey/pyvoip-project/tgvoipcall/python/start_B.log ./start_B_ro_${i}.log
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A_out.txt ./sw_ro_${i}_out.txt
        scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/start_A.log ./start_A_ro_${i}.log
        ls -al sw_ro_*.ogg
        ls -al *.txt      
done


##
#dublication

for (( i=10 ; $i<60 ; i=(($i+10)) ))
do
        echo "reorder = $i"
        # set netem
        command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
        command2="sudo /usr/sbin/tc qdisc add dev ens33 root netem delay 10ms duplicate ${i}%"
        echo ${command1}
        echo ${command2}
        ./tgvoipcall/python/parser.py > /dev/null 2>&1        
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python && ./parser.py > /dev/null 2>&1'
        ssh andrey@192.168.100.18 "${command1}"
        ssh andrey@192.168.100.18 "${command2}"
        ssh andrey@192.168.100.18 'sudo /usr/sbin/tc qdisc'
        cd /home/andrey/pyvoip-project/tgvoipcall/python/
        ./parser.py > /dev/null 2>&1 
        chmod 755 *.sh
        ./start_B.sh > start_B.log 2>&1 &
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python/ && chmod 755 *.sh && ./start_A.sh'
        pid=$( ps ax | grep tgvoipcall | grep -v grep | grep -v receive_udp_tgvoipcall.sh | awk '{print $1}' )
        echo ${pid}
        while kill -0 ${pid} 2> /dev/null; do sleep 1; done
        sleep 1
        cd ~/pyvoip-project/voice
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A.ogg ./sw_du_${i}.ogg    
        mv /home/andrey/pyvoip-project/tgvoipcall/python/start_B.log ./start_B_du_${i}.log
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A_out.txt ./sw_du_${i}_out.txt
        scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/start_A.log ./start_A_du_${i}.log
        ls -al sw_du_*.ogg
        ls -al *.txt      
done


##
#corruption

for (( i=2 ; $i<42 ; i=(($i+4)) ))
do
        echo "reorder = $i"
        # set netem
        command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
        command2="sudo /usr/sbin/tc qdisc add dev ens33 root netem delay 10ms corrupt ${i}%"
        echo ${command1}
        echo ${command2}
        ./tgvoipcall/python/parser.py > /dev/null 2>&1        
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python && ./parser.py > /dev/null 2>&1'
        ssh andrey@192.168.100.18 "${command1}"
        ssh andrey@192.168.100.18 "${command2}"
        ssh andrey@192.168.100.18 'sudo /usr/sbin/tc qdisc'
        cd /home/andrey/pyvoip-project/tgvoipcall/python/
        ./parser.py > /dev/null 2>&1 
        chmod 755 *.sh
        ./start_B.sh > start_B.log 2>&1 &
        ssh andrey@192.168.100.18 'cd /home/andrey/pyvoip-project/tgvoipcall/python/ && chmod 755 *.sh && ./start_A.sh'
        pid=$( ps ax | grep tgvoipcall | grep -v grep | grep -v receive_udp_tgvoipcall.sh | awk '{print $1}' )
        echo ${pid}
        while kill -0 ${pid} 2> /dev/null; do sleep 1; done
        sleep 1
        cd ~/pyvoip-project/voice
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A.ogg ./sw_co_${i}.ogg    
        mv /home/andrey/pyvoip-project/tgvoipcall/python/start_B.log ./start_B_co_${i}.log
        mv /home/andrey/pyvoip-project/tgvoipcall/python/sound_output_A_out.txt ./sw_co_${i}_out.txt
        scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/start_A.log ./start_A_co_${i}.log
        ls -al sw_co_*.ogg
        ls -al *.txt      
done

scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/sample17_in.txt ./
scp andrey@192.168.100.18:/home/andrey/pyvoip-project/tgvoipcall/python/sample17.opus ./
command1="sudo /usr/sbin/tc qdisc del dev ens33 root netem 2>/dev/null || true"
ssh andrey@192.168.100.18 "${command1}"
tar -cvzf sw-${DATE}.tgz sw*ogg start*log sw_*.txt sample17_in.txt sample17.opus
