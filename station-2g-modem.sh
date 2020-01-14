cat <<EOF > /etc/chatscripts/simcom-chat-connect
ABORT "BUSY"
ABORT "NO CARRIER"
ABORT "NO DIALTONE"
ABORT "ERROR"
ABORT "NO ANSWER"
TIMEOUT 30
"" AT
OK ATE0
OK ATI;+CSUB;+CSQ;+COPS?;+CGREG?;&D2
OK AT+SAPBR=3,1,"CONTYPE","GPRS"
OK AT+SAPBR=3,1,"APN","wireless.twilio.com"
OK AT+CGDATA="PPP"
CONNECT \c
EOF

cat <<EOF > /etc/ppp/peers/gprs
/dev/ttyS0 115200
# The chat script, customize your APN in this file
connect 'chat -s -v -f /etc/chatscripts/simcom-chat-connect '
# The close script
disconnect 'chat -s -v -f /etc/chatscripts/simcom-chat-disconnect'
# Hide password in debug messages
hide-password
# The phone is not required to authenticate
noauth
# Debug info from pppd
debug
# If you want to use the HSDPA link as your gateway
defaultroute
# pppd must not propose any IP address to the peer
noipdefault
# No ppp compression
novj
novjccomp
noccp
ipcp-accept-local
ipcp-accept-remote
local
# For sanity, keep a lock on the serial line
lock
modem
dump
nodetach
# Hardware flow control
nocrtscts
remotename 3gppp
ipparam 3gppp
ipcp-max-failure 30
# Ask the peer for up to 2 DNS server addresses
usepeerdns
maxfail 0
persist
EOF

reboot