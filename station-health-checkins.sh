#!/bin/bash
#
# install health checkin scripts - add to cronjob if not there
cat > /home/pi/ctt/health_checkin.sh <<- EOM
#!/bin/sh
#
# script that calls a python program to check-in to 
# server with voltage data

/usr/bin/python /home/pi/ctt//health_checkin.py
EOM
chmod +x /home/pi/ctt/health_checkin.sh

cat > /home/pi/ctt/health_checkin.py <<- EOM
from __future__ import division
# Sensor Output
# Copyright 2007-2019, Cellular Tracking Technologies, LLC, All Rights Reserved
# Version 1.0

# Python library imports

import json
import sys
import datetime
import os
import RPi.GPIO as GPIO
import time
import math
import bme680

# remove GPIO warnings

GPIO.setwarnings(False)

# configure GPIO mode

GPIO.setmode(GPIO.BCM)

# Configure ADC

_TLC_CS =19
_TLC_ADDR =21
_TLC_CLK =18
_TLC_DOUT =20
_TLC_EOC = 16

_ADC_BATTERY = 0
_ADC_SOLAR = 1
_ADC_RTC = 2
_ADC_TEMPERATURE = 3
_ADC_LIGHT = 4
_ADC_AUX_1 = 5
_ADC_AUX_2 = 6
_ADC_AUX_3 = 7
_ADC_AUX_4 = 8
_ADC_AUX_5 = 9
_ADC_AUX_6 = 10
_ADC_CAL_1 = 11
_ADC_CAL_2 = 12
_ADC_CAL_3 = 13
_ADC_VREF = 5.00

GPIO.setup(_TLC_CLK,GPIO.OUT)
GPIO.setup(_TLC_ADDR,GPIO.OUT)
GPIO.setup(_TLC_DOUT,GPIO.IN)
GPIO.setup(_TLC_CS,GPIO.OUT)
GPIO.setup(_TLC_EOC,GPIO.IN)

# ADC function 

def ADC_Read(channel):
    GPIO.output(_TLC_CS, 0)
    value = 0
    for i in range(0,4):
        if((channel >> (3-i)) & 0x01):
            GPIO.output(_TLC_ADDR, 1)
        else:
            GPIO.output(_TLC_ADDR, 0)
        GPIO.output(_TLC_CLK, 1)
        GPIO.output(_TLC_CLK, 0)
    for i in range(0, 6):
        GPIO.output(_TLC_CLK, 1)
        GPIO.output(_TLC_CLK, 0)
    GPIO.output(_TLC_CS, 1)
    time.sleep(0.001)
    GPIO.output(_TLC_CS, 0)
    for i in range(0, 10):
        GPIO.output(_TLC_CLK, 1)
        value <<= 1
        if (GPIO.input(_TLC_DOUT)):
            value |= 0x01
        GPIO.output(_TLC_CLK, 0)
    GPIO.output(_TLC_CS, 1)

    return value

def getVoltage():
    reading = ADC_Read(_ADC_BATTERY)
    voltage = (reading * 5) / 1024
    voltage = voltage / (100000/(599000))
    return round(voltage,2)

def getSolarVoltage():
    reading = ADC_Read(_ADC_SOLAR)
    voltage = (reading * 5) / 1024
    voltage = voltage / (100000/(599000))
    return round(voltage,2)

def getRTCBatteryVoltage():
    reading = ADC_Read(_ADC_RTC)
    voltage = _ADC_VREF / 1024 * reading
    return round(voltage,2)

def getSensorData():
    voltage = getVoltage()
    solar_voltage = getSolarVoltage()
    rtc_voltage = getRTCBatteryVoltage()
    return {
        'voltage': voltage,
        'solar_voltage': solar_voltage,
        'rtc_voltage': rtc_voltage,
    }

def getModemInfo():
    with open('/etc/station-id', 'r') as inFile:
        contents = inFile.read()
        return json.loads(contents)

if __name__ == '__main__':
    import httplib
    import datetime
    from hashlib import sha256

    try:
        sensor_data = getSensorData()
        modem_data = getModemInfo()
        now = datetime.datetime.utcnow()
        now_str = now.strftime('%Y-%m-%dT%H:%M:%S')
        secret='7e091f61-ffe8-46ce-b395-2e78db0e71a3'
        hash_str = '{}{}{}'.format(now_str, secret, modem_data['imei'])
        auth = sha256(hash_str).hexdigest()

        data = {
            'sensor': sensor_data,
            'modem': modem_data,
            'now': now_str,
            'auth': auth
        }
        payload = json.dumps(data)

        host = 'account.celltracktech.com'
        port = 443
        conn = httplib.HTTPSConnection(host=host, port=port)
        conn.request(
            method="POST",
            url="/station/v1/sensor/",
            body=payload
        )
        res = conn.getresponse()
        body = res.read()
    except Exception as err:
        # something went wrong trying to post the data
        pass
EOM

# write a new cronjob if a cronjob for this script is not already running
if grep -q health_checkin.sh /var/spool/cron/crontabs/pi; then
    # crojob already exists - ignoring
    echo "cronjob already exists"
else
    # adding new cronjob to run every hour at 51 minutes after the hour
	crontab -l -u pi > /tmp/pi-crontab
	echo "51 *	*	*	*	/home/pi/ctt/health_checkin.sh" >> /tmp/pi-crontab
	crontab -u pi /tmp/pi-crontab
	rm /tmp/pi-crontab
fi

# issue checkin now
/home/pi/ctt/health_checkin.sh