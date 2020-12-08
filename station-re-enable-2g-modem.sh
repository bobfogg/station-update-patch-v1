# make sure power pin line does not exist before adding it
sed '/gpio=25/d' -i /boot/config.txt
echo 'gpio=25=op,dh' >> /boot/config.txt
# toggle power to modem off
raspi-gpio set 25 op dh