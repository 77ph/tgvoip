#!/bin/bash
if [ ! -f /usr/local/bin/shc ]; then  
git clone https://github.com/neurobin/shc.git
cd shc/
./configure
make
sudo make install
cd ..
rm -rf shc
fi

/usr/local/bin/shc -fr ./tgvoiprate.sh -o ./tgvoiprate



