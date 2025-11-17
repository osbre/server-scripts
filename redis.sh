apt install redis-server -y

systemctl enable redis
systemctl start redis
systemctl status redis
