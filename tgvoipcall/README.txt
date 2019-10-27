Для сборки требуется библиотека libtgvoip:

git clone --recursive https://github.com/telegramdesktop/libtgvoip.git
cd libtgvoip
git checkout d4a0f719ffd8d29e88474f67abc9fc862661c3b9
export CFLAGS="-O3"
export CXXFLAGS="-O3"
autoreconf --force --install
./configure --enable-audio-callback
make
make install

cd ..
cp libtgvoip/.libs/libtgvoip.a ./
make

tgvoipcall не требует установки libtgvoip на машину, где он будет запускаться (libtgvoip.a линкуется статически)

----------------------------------

Для генерации скриптов запуска можно использовать утилиту для генерации:
./parser.py sound_A.ogg sound_output_B.ogg sound_B.ogg sound_output_A.ogg 

auth_token содержится в ./parser.py 

После запуска 
./parser.py ./sound_A.ogg ./sound_output_B.ogg ./sound_B.ogg ./sound_output_A.ogg

генерируются два стартовых файла вида:

cat start_A.sh 
./tgvoipcall 134.209.178.88:559 4ada8a5c9255b563646d2fb0f7d876c1 -k 727d8180a17940c72b08a1983997b038036b76b0e9ac9b79f965b1f6edb6913b130ac965def5804df35db6a2622d7270f16cad77c7fe78c773dc90574661b53ecca5b12b6955883b323942fdf43760377ccbc7c4b4fc85c01499ca482508c3a76d4aa5af65c8e209a19d448134ac191c52f61c7637277bfd2160d9b844332e0ab75b40a1e60a2998f4bc458ce1327699902f8eacb5693c4ab4c986fed2513445fc92a4fa928fcbcfdf7df9ec373a1130608f2cb2d23ebef8be13a5e5b50e7a99cba922b9b63913fda5f12a732becae5be0898b6952b2988cf7e242f7c382238057c4a519350d1412565decbefd8187f880c10d120348bb97ed1e05292f1921e0 -i ./sound_A.ogg -o ./sound_output_B.ogg -c config.json -l 2403148608088 -r caller

cat start_B.sh
./tgvoipcall 134.209.178.88:559 4bda8a5c9255b563646d2fb0f7d876c1 -k 727d8180a17940c72b08a1983997b038036b76b0e9ac9b79f965b1f6edb6913b130ac965def5804df35db6a2622d7270f16cad77c7fe78c773dc90574661b53ecca5b12b6955883b323942fdf43760377ccbc7c4b4fc85c01499ca482508c3a76d4aa5af65c8e209a19d448134ac191c52f61c7637277bfd2160d9b844332e0ab75b40a1e60a2998f4bc458ce1327699902f8eacb5693c4ab4c986fed2513445fc92a4fa928fcbcfdf7df9ec373a1130608f2cb2d23ebef8be13a5e5b50e7a99cba922b9b63913fda5f12a732becae5be0898b6952b2988cf7e242f7c382238057c4a519350d1412565decbefd8187f880c10d120348bb97ed1e05292f1921e0 -i ./sound_B.ogg -o ./sound_output_A.ogg -c config.json -l 2403148608088 -r callee

Рекомендуемый метод их запуска:
./start_A.sh > start_A.log 2>&1 &
./start_B.sh > start_B.log 2>&1 &

Примечание:
./tgvoipcall содержит в командной строке дополнительный параметр -l id cоотвествующий ответу API: { "id":1117254731 }. При использовании утилиты parser.py этот параметр извлекается из ответа API. 

Используйте полные пути вида: /path/to/sound_A.ogg (см. https://contest.com/docs/voip/ru )
