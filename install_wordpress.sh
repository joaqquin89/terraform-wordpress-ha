#!/bin/bash
sudo echo "127.0.0.1 `hostname`" >> /etc/hosts
sudo apt-get update -y
sudo apt-get install mysql-client -y
sudo apt-get install apache2 apache2-utils -y
sudo apt-get install php5 -y
sudo apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-curl php5-gd php5-xmlrp -y
sudo apt-get install php5-mysqlnd-ms -y
sudo service apache2 restart
sudo apt-get install -y git binutils make
git clone https://github.com/aws/efs-utils
cd efs-utils && make deb
sudo apt-get install -y ./build/amazon-efs-utils*deb
efs_id="${module.create_efs.id}"
cd ..
sudo wget -c http://wordpress.org/wordpress-5.1.1.tar.gz
sudo tar -xzvf wordpress-5.1.1.tar.gz
sleep 20
sudo mkdir -p /var/www/html/
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.us-east-1.amazonaws.com:/ /var/www/html/
# Edit fstab so EFS automatically loads on reboot
sudo echo ${efs_id}.efs.us-east-1.amazonaws.com:/ /var/www/html/ efs defaults,_netdev 0 0 >> /etc/fstab
sudo rsync -av wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo service apache2 restart
sleep 20