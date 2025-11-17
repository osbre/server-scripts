apt install redis-server -y

systemctl enable redis-server
systemctl start redis-server
systemctl status redis-server
