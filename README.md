# UPS PushAll Notification

Sending notifications when UPS status changes

**Install**
1.  Before installation, make sure that you have curl and apcupsd packages installed.
2.  Clone this repository in a convenient way.
3.  Cd /path/to/ups-pushall.
4.  Copy ups.example.conf to ups.conf.
5.  Configure your `ups.conf` file.
6.  Run the script to test
    
    `./ups.sh test`
7.  Run script `ups.sh` in background in a convenient way.

**Example**
```
(/path/to/ups.sh &> /dev/null) &
(/path/to/ups.sh &> /var/log/ups.log) &
```

**Example of config file**
```
TYPE="self" // request types (self, broadcast, multicast, unicast). Required
ID=1234 // channel or account id. Required
KEY="676a0e64bdc0befcab35376984d95790" // channel or account key. Required
TTL=86400 // lifetime in seconds. Default 86400 - day
UIDD=1234 // user id for unicast request. Required only if using unicast request
UIDS="[1234,1235,1237]" // users id for multicast request. Required only if using multicast request
FILE="/var/log/apcupsd.status" // location of status file apcupsd. Required
TITLE="Status #upsname" // Push notification title
TEXT="Status UPS: #status Battery Charge: #bcharge% Time Left: #timeleft" // Push notification text
INTERVAL=15 // polling interval. Default 15 seconds
BATT_INTERVAL=0 // polling interval on battery power. Default disable
```

**Documentation**

[Full documentation PushAll](https://pushall.ru/blog/api)

