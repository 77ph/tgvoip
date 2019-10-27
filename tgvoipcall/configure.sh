sudo apt-get install build-essential
apt install sudo
sudo apt-get install build-essential
sudo apt-get install manpages-dev
sudo apt-get install git
sudo apt-get install libssl-dev
sudo apt-get install libopus-dev
sudo apt-get install libpulse-dev 
sudo apt-get install libasound-dev
sudo apt-get install automake     
sudo apt-get install libtool
sudo apt-get install cmake
sudo apt-get install python3-dev
sudo apt-get install python3-pip
sudo apt-get install cmake
sudo apt-get install opus-tools


sudo apt-get install python3-scipy
sudo apt-get install python3-pandas
sudo apt-get install python3-numpy
sudo apt-get install python3-sklearn

--- tgvoiprate
pip3 install numpy
pip3 install scipy
pip3 install sklearn
pip3 install librosa

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

cp ./libtgvoip/.libs/libtgvoip.a ./


