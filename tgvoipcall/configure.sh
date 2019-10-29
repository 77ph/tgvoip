sudo apt-apt -y install sudo
sudo apt-get -y install build-essential
sudo apt-get -y install manpages-dev
sudo apt-get -y install git
sudo apt-get -y install libssl-dev
sudo apt-get -y install libopus-dev
sudo apt-get -y install libpulse-dev 
sudo apt-get -y install libasound-dev
sudo apt-get -y install automake     
sudo apt-get -y install libtool
sudo apt-get -y install cmake
sudo apt-get -y install python3-dev
sudo apt-get -y install python3-pip
sudo apt-get -y install opus-tools
sudo apt-get -y install python3-scipy
sudo apt-get -y install python3-pandas
sudo apt-get -y install python3-numpy
sudo apt-get -y install python3-sklearn

#--- tgvoiprate
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
sudo make install
cd ..

cp ./libtgvoip/.libs/libtgvoip.a ./


