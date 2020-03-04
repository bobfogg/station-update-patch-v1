# disable modem power from boot
sed '/gpio=25/d' -i /boot/config.txt
# toggle power to modem off
raspi-gpio set 25 dl
sleep 0.3
raspi-gpio set 25 op dh
sleep 1.3
raspi-gpio set 25 dl