# install cmake for c project build tools
sudo apt update
sudo apt install -y cmake

# blacklist modules so system doesn't lock up rtl-sdr as audio
cat <<EOF >/etc/modprobe.d/no-rtl.conf
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF

# remove the librtlsdr directory if it exists
rm -rf /home/pi/proj/librtlsdr

cd /home/pi/proj
# clone librtlsdr software
git clone https://github.com/bobfogg/librtlsdr.git
cd librtlsdr
# reset to code base from 2018 sensorgnome image 
git reset --hard d9bbeea45568b0191e4ea0b081be427b18a893f5
# compile the source, install
mkdir build
cd build
cmake ../
make
make uninstall
make install
ldconfig

# create symlink 
sudo ln -s /usr/local/bin/rtl_tcp /usr/bin

reboot
