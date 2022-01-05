#! /bin/bash

# Update repositores of Ubuntu
apt-get update
apt-get install -y awscli

# Get own IP of Ec2 instance
SELFIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Send logs of User data to console in CloudWatch
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

mkdir -p ${HOME}/autostart
chown -R ubuntu:ubuntu ${HOME}/autostart
mkdir -p ${HOME}/airflow/dags
mkdir -p ${HOME}/airflow/plugins
mkdir -p ${HOME}/airflow/logs
chown -R ubuntu:ubuntu ${HOME}/airflow

# Install Docker
curl https://get.docker.com | bash

# Install Docker-Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

usermod -aG docker ubuntu

# Install Airflow with docker-compose
cd ${HOME}/airflow
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.2.3/docker-compose.yaml'

# Replace some variables in docker-compose.yaml
sed -i "s/AIRFLOW__CORE__LOAD_EXAMPLES: 'true'/AIRFLOW__CORE__LOAD_EXAMPLES: 'false'/g" ${HOME}/airflow/docker-compose.yaml
sed -i "s/AIRFLOW__CORE__EXECUTOR: CeleryExecutor/AIRFLOW__CORE__EXECUTOR: LocalExecutor/g" ${HOME}/airflow/docker-compose.yaml

# sed '/{    redis:/{:a;N;/condition}/!ba};/ID: 222/d' docker-compose.yaml
# sed "/    redis:\n      condition: service_healthy/d" docker-compose.yaml
docker-compose up -d
docker-compose stop redis
docker-compose stop airflow-worker
docker-compose stop flower

chmod -R 777 ${HOME}/airflow/dags
chmod -R 777 ${HOME}/airflow/logs
chmod -R 777 ${HOME}/airflow/plugins

# Install aws s3 sync service
tee -a ${HOME}/autostart/s3sync.sh > /dev/null <<EOT
#!/bin/bash

while true; do
    aws s3 sync s3://${S3BUCKET}/dags ${HOME}/airflow/dags
    sleep 60
done
EOT
chmod +x ${HOME}/autostart/s3sync.sh

tee -a /lib/systemd/system/s3sync.service > /dev/null <<EOT
[Unit]
Description=S3 Sync Service
Wants=network-online.target
After=network-online.target
[Service]
User=ubuntu
Group=ubuntu
Restart=always
RestartSec=3
ExecStart=${HOME}/autostart/s3sync.sh
[Install]
WantedBy=default.target
EOT

systemctl enable s3sync.service
systemctl start s3sync.service
