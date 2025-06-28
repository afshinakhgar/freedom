
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/failover-check.sh") | crontab -


- kharej
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-server.sh") | crontab -

