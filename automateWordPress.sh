#!/bin/bash

set -e

BASE_DIR="/opt/elite-wp-packages"
WP_ZIP="/root/wp.zip"

echo "Enter client name (no spaces, lowercase, e.g. client1):"
read CLIENT

if [[ -z "$CLIENT" ]]; then
  echo "Client name cannot be empty."
  exit 1
fi

CLIENT_DIR="${BASE_DIR}/${CLIENT}"
mkdir -p "$CLIENT_DIR"

# Generate strong passwords
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
MYSQL_USER="wpuser"
MYSQL_PASSWORD=$(openssl rand -base64 16)
MYSQL_DATABASE="wpdb"

WP_ADMIN_USER="elite"
WP_ADMIN_EMAIL="welcome@elite-strategies.com"
WP_ADMIN_PASSWORD=$(openssl rand -base64 16)

SFTP_USER="${CLIENT}sftp"
SFTP_PASSWORD=$(openssl rand -base64 12)

WP_URL="http://${CLIENT}.elite04.com"
PHPMYADMIN_URL="http://${CLIENT}.elite04.com:8080"

# Unzip WordPress package
mkdir -p "${CLIENT_DIR}/html"
unzip -q "$WP_ZIP" -d "${CLIENT_DIR}/html"

# Create docker-compose.yml
cat > "${CLIENT_DIR}/docker-compose.yml" <<EOF
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: ${CLIENT}_db
    restart: always
    environment:
      MYSQL_DATABASE: $MYSQL_DATABASE
      MYSQL_USER: $MYSQL_USER
      MYSQL_PASSWORD: $MYSQL_PASSWORD
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
    volumes:
      - db_data_${CLIENT}:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    container_name: ${CLIENT}_wp
    depends_on:
      - db
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: $MYSQL_USER
      WORDPRESS_DB_PASSWORD: $MYSQL_PASSWORD
      WORDPRESS_DB_NAME: $MYSQL_DATABASE
      WORDPRESS_TABLE_PREFIX: wp_
    volumes:
      - ./html:/var/www/html
    ports:
      - "0.0.0.0:0:80"

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ${CLIENT}_pma
    depends_on:
      - db
    restart: always
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
    ports:
      - "8080:80"

  sftp:
    image: atmoz/sftp
    container_name: ${CLIENT}_sftp
    restart: always
    volumes:
      - ./html:/home/${SFTP_USER}/wordpress
    ports:
      - "2222:22"
    command: ${SFTP_USER}:${SFTP_PASSWORD}:1001

volumes:
  db_data_${CLIENT}:
EOF

# Start the containers
cd "$CLIENT_DIR"
docker-compose up -d

# Wait for the WordPress container to be running
echo "Waiting for WordPress container to start..."
while [ "$(docker ps -q -f name=${CLIENT}_wp)" == "" ]; do
  sleep 2
done

# Wait for WordPress to be ready inside the container
echo "Waiting for WordPress to initialize..."
until docker exec ${CLIENT}_wp curl -s http://localhost/wp-admin/install.php | grep -q "WordPress"; do
  sleep 5
done

# Install WP-CLI if not present in the container
docker exec ${CLIENT}_wp bash -c "if ! command -v wp &> /dev/null; then curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp; fi"

# Run WordPress installation and create admin user
docker exec ${CLIENT}_wp wp core install \
  --url="$WP_URL" \
  --title="Elite Client Site" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASSWORD" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --skip-email --path=/var/www/html --allow-root

# Save credentials for later output
cat > "${CLIENT_DIR}/credentials.txt" <<EOF
WordPress URL: $WP_URL
WordPress Admin Username: $WP_ADMIN_USER
WordPress Admin Password: $WP_ADMIN_PASSWORD
WordPress Admin Email: $WP_ADMIN_EMAIL

MySQL Database: $MYSQL_DATABASE
MySQL User: $MYSQL_USER
MySQL Password: $MYSQL_PASSWORD
MySQL Root Password: $MYSQL_ROOT_PASSWORD

phpMyAdmin URL: $PHPMYADMIN_URL

SFTP Host: $(hostname -I | awk '{print $1}')
SFTP Port: 2222
SFTP User: $SFTP_USER
SFTP Password: $SFTP_PASSWORD
SFTP Directory: /wordpress
EOF

echo
echo "=============================================="
echo "Setup complete for client: $CLIENT"
echo "Credentials and access details are saved in:"
echo "  ${CLIENT_DIR}/credentials.txt"
echo "----------------------------------------------"
cat "${CLIENT_DIR}/credentials.txt"
echo "=============================================="
echo
echo "To stop or remove this client's containers:"
echo "  cd ${CLIENT_DIR}"
echo "  docker-compose down   # (to stop and remove containers)"
echo
echo "To view logs:"
echo "  docker-compose logs -f"
echo
