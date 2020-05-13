cat > /etc/udev/rules.d/15-station-modem.rules <<-'EOF'
# Symlink for Station Modem

# note bInterfaceNumber
SUBSYSTEMS=="usb", ENV{.LOCAL_ifNum}="$attr{bInterfaceNumber}"

# adding symlink for modem
SUBSYSTEM=="tty", ACTION=="add", \
	ATTRS{idVendor}=="1e2d", ATTRS{idProduct}=="005b", \
	ENV{.LOCAL_ifNum}=="00", SYMLINK+="station_modem"

SUBSYSTEM=="tty", ACTION=="add", \
	ATTRS{idVendor}=="1e2d", ATTRS{idProduct}=="005b", \
	ENV{.LOCAL_ifNum}=="02", SYMLINK+="station_modem_status"
EOF

cat <<EOF > /etc/chatscripts/twilio-super
# Exit executition if module receives any of the following strings:
ABORT 'BUSY'
ABORT 'NO CARRIER'
ABORT 'NO DIALTONE'
ABORT 'NO DIAL TONE'
ABORT 'NO ANSWER'
ABORT 'DELAYED'
TIMEOUT 10
REPORT CONNECT

# Module will send the string AT regardless of the string it receives
"" AT

# Instructs the modem to disconnect from the line, terminating any call in progress. All of the functions of the command shall be completed before the modem returns a result code.
OK ATH

# Instructs the modem to set all parameters to the factory defaults.
OK ATZ

# Result codes are sent to the Data Terminal Equipment (DTE).
OK ATQ0

# who are we?
OK ATI1

# are we connected
OK AT+CGACT?

# perform a detatch
"" AT+CGACT=0

# are we connected
OK AT+CGACT?

# perform a detatch
"" AT+CGACT=0

# are we connected
OK AT+CGACT?

# Define PDP context 
"" AT+CGDCONT=1,"IP","super"

# ATDT = Attention Dial Tone
OK ATDT*99***1#

# Don't send any more strings when it receives the string CONNECT. Module considers the data links as having been set up.
CONNECT ''
EOF

cat <<EOF > /etc/chatscripts/disconnect
# Name: gprs-disconnect-chat
# Purpose: GPRS PPP Disconnect Script
# Notes: CHAT is used to issue modem AT commands.  See CHAT man pages for more info.
#
exec /usr/sbin/chat -V -s -S \
ABORT "BUSY" \
ABORT "ERROR" \
ABORT "NO DIALTONE" \
SAY "n\Sending break to the modem\n" \
"" "\K" \
"" "\K" \
"" "\K" \
"" "+++ATH" \
"" "+++ATH" \
"" "+++ATH" \
SAY "\nPDP context detached\n"
EOF


cat <<EOF > /etc/ppp/peers/twilio-super

# The chat script, customize your APN in this file

# modem serial 
/dev/station_modem 921600

connect 'chat -s -v -f /etc/chatscripts/twilio-super'

# The close script
disconnect 'chat -s -v -f /etc/chatscripts/disconnect'

# Hide password in debug messages
hide-password
# The phone is not required to authenticate
noauth
# Debug info from pppd
debug
# If you want to use the HSDPA link as your gateway
defaultroute
replacedefaultroute
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
#holdoff 600
#nolog
EOF

rm /etc/ppp/peers/gprs
ln -s /etc/ppp/peers/twilio-super /etc/ppp/peers/gprs

reboot