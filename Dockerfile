FROM ubuntu:14.04.3

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Timezone
RUN echo "Asia/Bangkok" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Install Nginx & PHP
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:nginx/stable && add-apt-repository -y ppa:ondrej/php5-5.6
RUN apt-get update && apt-get install -y \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    npm \
    supervisor \
    nginx \
    php5-fpm \
    php5-curl \
    php5-gd \
    php5-geoip \
    php5-imagick \
    php5-json \
    php5-ldap \
    php5-mcrypt \
    php5-memcache \
    php5-memcached \
    php5-mongo \
    php5-mysqlnd \
    php5-pgsql \
    php5-redis \
    php5-sqlite \
    php5-xmlrpc \
    php5-xcache \
    php5-intl \
    php5-gearman \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Phalcon
RUN git clone -b 1.3.6 https://github.com/phalcon/cphalcon.git
RUN sudo apt-get update && apt-get install php5-dev -y
RUN cd cphalcon/build && ./install 
RUN echo "extension=phalcon.so" >> /etc/php5/mods-available/phalcon.ini
RUN php5enmod phalcon && service php5-fpm restart 

# Nginx & PHP configuration
COPY conf/vhosts/* /etc/nginx/sites-available
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/php.ini /etc/php5/fpm/php.ini
COPY conf/cli.php.ini /etc/php5/cli/php.ini
COPY conf/php-fpm.conf /etc/php5/fpm/php-fpm.conf
COPY conf/www.conf /etc/php5/fpm/pool.d/www.conf
COPY conf/certs/cert.pem /etc/nginx/certs/cert.pem
COPY conf/certs/key.pem /etc/nginx/certs/key.pem

# Enable vhosts
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/tiki.frontend.conf /etc/nginx/sites-enabled/tiki.frontend.conf

# Supervisord configuration
ADD conf/supervisord.conf /etc/supervisord.conf

# Forward request and error logs to docker log collector
#RUN ln -sf /dev/stdout /var/log/nginx/access.log
#RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Composer & support parallel install
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN composer global require hirak/prestissimo

# Npm
RUN ln -fs /usr/bin/nodejs /usr/local/bin/node
RUN npm config set registry http://registry.npmjs.org/
RUN npm config set strict-ssl false 
RUN npm install -g bower grunt-cli gulp-cli

# Start Supervisord
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]

#RUN chmod -R 777 /src/var/log 
