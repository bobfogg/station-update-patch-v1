# Update Scripts for CTT Sensor Station v1

## station-lte-modem.sh
* use a [Zoom 4625 USB Modem](http://www.zoomtel.com/techsupport/cell-modems/4625-4626/)

## station-2g-modem.sh
* use the on board 2g modem

## station-checkin.sh
* runs a python script to check into the server

## station-rtlsdr.sh
* installs software to enable RTL-SDR support on the SensorGnome software

## station-health-checkins.sh
* installs (writes) a python script that checks into our server backend with voltage information every hour
* writes a bash script that calls the python script - used in the cronjob
* checks if a cronjob exists that calls the bash script - if it does not exist: add the script to run at 51 minutes after the hour
* runs the script to checkin at the time update is applied