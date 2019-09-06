import threading
import json
import os
import httplib
import gps
import time
import signal

def checkin():
  # debug
  #url = "wildlife-debug.celltracktech.net"
  #port = 8014

  # production
  url = "account.celltracktech.com"
  port = 80 

  # Generate data JSON to send to server
  with open('/etc/station-id', 'r') as inFile:
    data = json.loads(inFile.read())
  postData = {
    'modem': {
      'sim': data.get('sim'),
      'imei': data.get('imei')
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

# Signal handler for proper gps.next() timeout
def sigHandler(signum, frame):
  print "Stopped waiting for gps.next()"
  raise Exception("Timeout")

def getGpsNext(gpsd):
  return gpsd.next()

def getGpsDefault():
  return {
        'lat': None,
        'lng': None,
        'time': None
      }

def getGps():
  gpsd = gps.gps(mode=gps.WATCH_ENABLE|gps.WATCH_NEWSTYLE)
  n = 0
  while True:
    n += 1
    print "n = " + str(n)
    signal.signal(signal.SIGALRM, sigHandler)
    signal.alarm(5)
    try:
      report = getGpsNext(gpsd)
    except Exception, exc:
      print exc
    print("gpsd.next() done")
    latlontime = {"lat":None, "lon":None, "time":None}
    if report['class'] == 'TPV':
      for key in ('lat', 'lon', 'time'):
        try:
          latlontime[key] = report[key]
        except KeyError:
          print "Error: key '" + key + "' not found"
      return {
        'lat': latlontime['lat'],
        'lng': latlontime['lon'],
        'time': latlontime['time']
      }
    if n > 5:
      return getGpsDefault()
    time.sleep(1)

def getMeta():
  serial, revision, hardware = getCPUInfo()
  bootcount = getBootCount()
  uptime = getUptime()
  tot_m, used_m, free_m = getMemoryStats()
  diskTotal, diskAvail = getDiskUsage()
  return {
    'serial': serial,
    'hardware': hardware,
    'revision': revision,
    'total_mem': tot_m*1024,
    'disk_total': diskTotal,
    'disk_available': diskAvail,
    'free_mem': free_m*1024,
    'uptime': uptime,
    'bootcount': bootcount,
    'loadavg_15min': 0,
  }

def getDiskUsage():
  used, available = os.popen('df | grep /dev/root').readline().split()[2:4]
  total = int(used) + int(available)
  return int(total), int(available)

def getUptime():
  return int(float(open('/proc/uptime', 'r').read().split()[0]))

def getBootCount():
  return open('/etc/bootcount', 'r').read().strip()

def getMemoryStats():
  total, used, free = map(int, os.popen('free -t').readlines()[-1].split()[1:])
  return total, used, free

def getCPUInfo():
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
  return serial, revision, hardware

checkin()
