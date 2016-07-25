FROM centos

### Install Repo

RUN yum clean all && rm -f /var/cache/yum/timedhosts.txt && cp -rf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
RUN yum install -y epel-release 
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

RUN curl --silent --location https://rpm.nodesource.com/setup_6.x | bash - 


ADD php/remi-release-7.rpm /tmp/remi-release-7.rpm
RUN yum install /tmp/remi-release-7.rpm -y 
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi
ADD php/remi.repo /etc/yum.repos.d/remi.repo

ADD nginx/nginx-release-centos-7-0.el7.ngx.noarch.rpm /tmp/nginx-release-centos-7-0.el7.ngx.noarch.rpm
RUN yum install -y /tmp/nginx-release-centos-7-0.el7.ngx.noarch.rpm && rm -rf /etc/nginx/conf.d/*.conf 

RUN yum install -y git vim wget curl iftop net-tools bind-utils telnet supervisor gcc gcc-devel 

### Install PHP 
RUN yum install -y \
    php \php-cli \
	php-fpm \
	php-curl \
	php-devel \
	php-gd \
	php-geoip \
	php-imagick \
	php-json \
	php-ldap \
	php-mcrypt \
	php-memcache \
    php-memcached \
    php-mongo \
    php-mysqlnd \
    php-pgsql \
    php-redis \
    php-sqlite \
    php-xmlrpc \
    php-xcache \
    php-xdebug \
    php-intl \
	nginx \	
	nodejs \
    && yum clean all && rm -rf /etc/php.d/15-xdebug.ini

RUN git clone -b 1.3.6 https://github.com/phalcon/cphalcon.git \
&& cd cphalcon/build && ./install \
&& echo "extension=phalcon.so" >> /etc/php.d/50-phalcon.ini

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/bin/composer && chmod +x /usr/bin/composer
RUN composer global require hirak/prestissimo 
RUN npm install -g npm bower grunt-cli gulp-cli
	  
# Create nginx web root folder
RUN mkdir -p /src/webroot/frontend /src/webroot/api_internal /src/webroot/backend /src/webroot/api /src/webroot/api_v2

# PHP Configuration
COPY php/php.ini /etc/php.ini
COPY php/php-fpm.conf /etc/php-fpm.conf
COPY php/www.conf /etc/php-fpm.d/www.conf
COPY php/xdebug.ini /etc/php.d/xdebug.ini

### Install Nginx && Module pagespeed 
COPY nginx/nginx-module-pagespeed-1.11.33.2-1.el7.centos.tiki.x86_64.rpm /tmp/nginx-module-pagespeed-1.11.33.2-1.el7.centos.tiki.x86_64.rpm
RUN rpm -Uvh /tmp/nginx-module-pagespeed-1.11.33.2-1.el7.centos.tiki.x86_64.rpm
COPY nginx/certs /etc/nginx/certs
COPY nginx/vhosts/* /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

### Add user www-data 
RUN groupadd -g 1000 www-data 
RUN useradd -g 1000 -u 1000 www-data

### Add supervisord cho Worker

### Add Logs folder 
RUN mkdir -p /var/log/php-fpm /var/log/nginx  /var/log/supervisor && rm -rf /tmp/*

EXPOSE 80 443 9001

### ENTRYPOINT ["/usr/bin/supervisord", "/etc/supervisord.conf"]
ADD supervisor/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
