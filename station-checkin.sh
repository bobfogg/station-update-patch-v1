cat > /home/pi/manual_checkin.py <<- 'EOM'
import json
import os
import httplib
import gps
import time

def getGps():
  gpsd = gps.gps(mode=gps.WATCH_ENABLE|gps.WATCH_NEWSTYLE)
  n = 0
  while True:
    n += 1
    report = gpsd.next()
    if report['class'] == 'TPV':
      return {
        'lat': report['lat'],
        'lng': report['lon'],
        'time': report['time']
      }
    if n > 10:
      return {
        'lat': -1,
        'lng': -1,
        'time': 0 
      }
    time.sleep(1)

def checkin():
  url = "wildlife-debug.celltracktech.net"
  port = 8014
  url = "account.celltracktech.com"
  port = 80 
  with open('/etc/station-id', 'r') as inFile:
    data = json.loads(inFile.read())
  postData = {
    'modem': {
      'sim': data.get('sim'),
      'imei': data.get('imei')
    },
    'gps': {
      'lat': -1,
      'lng': -1,
      'time': -1
    },
    'module': getMeta(),
    'gps': getGps(),
    'beep_count': 0,
    'unique_tags': 0,
  }
  print(postData)
  conn = httplib.HTTPConnection(url, port)
  conn.request("POST", "/station/v1/checkin/", json.dumps(postData))
  response = conn.getresponse()
  print(response.status, response.reason)

def getMeta():
  serial = None
  revision = None
  hardware = None
  with open('/proc/cpuinfo','r') as inFile:
    for line in inFile:
      vals = line.split(':')
      if len(vals) > 1:
        key = vals[0].strip()
        value = vals[1].strip()
        if key == 'Serial':
          serial = value
        if key == 'Revision':
          revision = value
        if key == 'Hardware':
          hardware = value
  bootcount = open('/etc/bootcount', 'r').read().strip()
  uptime = int(float(open('/proc/uptime', 'r').read().split()[0]))
  tot_m, used_m, free_m = map(int, os.popen('free -t').readlines()[-1].split()[1:])
  return {
    'serial': serial,
    'hardware': hardware,
    'revision': revision,
    'total_mem': tot_m*1024,
    'disk_total': 0,
    'disk_available': 0,
    'free_mem': free_m*1024,
    'uptime': uptime,
    'bootcount': bootcount,
    'loadavg_15min': 0,
  }

checkin()
EOM
chown pi:ip /home/pi/manual_checkin.py
python /home/pi/manual_checkin.py