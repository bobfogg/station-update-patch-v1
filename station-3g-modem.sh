#/bin/bash
sudo sed '2 s/^.*$/\/dev\/ttyUSB0/' -i /etc/ppp/peers/gprs
sudo sync
sudo reboot

