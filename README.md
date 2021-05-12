# UPS Pushall Notification

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

**Documentation**

[Full documentation](https://pushall.ru/blog/api)

