#!/bin/bash
set -e  # 遇到错误时终止脚本

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# 更新系统
log_success "Updating system..."
apt update && apt upgrade -y || log_error "Failed to update system!"

# 安装 LAMP 组件
log_success "Installing Apache, MariaDB, and PHP..."
apt install -y apache2 mariadb-server php php-mysqli php-gd php-curl php-xml unzip git ca-certificates || log_error "Failed to install LAMP stack!"

# 启动服务
log_success "Starting Apache and MySQL..."
service apache2 start || log_error "Failed to start Apache!"

# 确保MySQL数据目录权限正确
chown -R mysql:mysql /var/lib/mysql
chmod 750 /var/lib/mysql

# 检查MySQL是否已经运行
if ! pgrep -x "mariadbd" > /dev/null; then
    log_success "Starting MySQL..."
    # 移除 --skip-networking 参数
    mysqld_safe &
    sleep 10  # 等待MySQL完全启动
else
    log_success "MySQL is already running..."
    # 如果MySQL已经在运行，需要重启以确保配置正确
    pkill mariadbd
    sleep 5
    mysqld_safe &
    sleep 10
fi

# 配置数据库
log_success "Configuring MariaDB..."
mysql -u root <<EOF || log_error "Failed to configure database!"
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'dvwa_password';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
EOF
log_success "Database configured successfully."

# 下载 DVWA
# 启用必要的Apache模块
log_success "Enabling Apache modules..."
a2enmod rewrite || log_error "Failed to enable mod_rewrite!"

log_success "Downloading DVWA..."
cd /var/www/html || log_error "Failed to change directory!"
rm -rf DVWA  # 删除已有的 DVWA 目录，避免冲突
git config --global http.sslVerify false
git clone https://github.com/digininja/DVWA.git || log_error "Failed to download DVWA!"

# Create vendor directory manually
log_success "Creating vendor directory..."
mkdir -p /var/www/html/DVWA/vendor
chmod 755 /var/www/html/DVWA/vendor

# Remove the Composer installation part and continue with DVWA configuration
log_success "Configuring DVWA..."
cd /var/www/html/DVWA/config || log_error "Failed to access config directory!"
cp config.inc.php.dist config.inc.php || log_error "Failed to copy config file!"

# 修改数据库信息
sed -i "s/'db_user'.*/'db_user' ] = 'dvwa';/" config.inc.php
sed -i "s/'db_password'.*/'db_password' ] = 'dvwa_password';/" config.inc.php
sed -i "s/'db_database'.*/'db_database' ] = 'dvwa';/" config.inc.php
sed -i "s/'recaptcha_public_key'.*/'recaptcha_public_key' ] = '6LdK7xITAAzzAAJQTfL7fu6I-0aPl8KHHieAT_yJg';/" config.inc.php
sed -i "s/'recaptcha_private_key'.*/'recaptcha_private_key' ] = '6LdK7xITAzzAAL_uw9YXVUOPoIHPZLfw2K1n5NVQ';/" config.inc.php

# 设置权限
log_success "Setting permissions..."
chown -R www-data:www-data /var/www/html/DVWA || log_error "Failed to set ownership!"
chmod -R 755 /var/www/html/DVWA || log_error "Failed to set permissions!"

# 配置 Apache
log_success "Configuring Apache..."
cat > /etc/apache2/sites-available/dvwa.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@dvwa.local
    DocumentRoot /var/www/html/DVWA

    <Directory /var/www/html/DVWA>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# 启用 DVWA 站点并重启 Apache
a2ensite dvwa.conf || log_error "Failed to enable Apache site!"
service apache2 restart || log_error "Failed to restart Apache!"

# 修改 PHP 配置
log_success "Configuring PHP..."
# 修改所有可能的 PHP 配置文件
find /etc/php/ -name "php.ini" -exec sed -i 's/allow_url_include = Off/allow_url_include = On/' {} \;
find /etc/php/ -name "php.ini" -exec sed -i 's/display_errors = Off/display_errors = On/' {} \;
find /etc/php/ -name "php.ini" -exec sed -i 's/display_startup_errors = Off/display_startup_errors = On/' {} \;

# 确保 /var/www/html/DVWA/hackable/uploads/ 和 /var/www/html/DVWA/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt 可写
mkdir -p /var/www/html/DVWA/hackable/uploads/
mkdir -p /var/www/html/DVWA/external/phpids/0.6/lib/IDS/tmp/
touch /var/www/html/DVWA/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt
chmod 777 /var/www/html/DVWA/hackable/uploads/
chmod 777 /var/www/html/DVWA/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt

# 重启 Apache 服务
log_success "Restarting services..."
service apache2 restart || log_error "Failed to restart Apache!"

# 完成
log_success "DVWA installation completed!"
echo -e "You can now access DVWA at: ${YELLOW}http://$(hostname -I | awk '{print $1}')/DVWA${NC}"
