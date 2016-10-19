FROM ubuntu:latest

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Timezone
RUN echo "Asia/Bangkok" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ondrej/php && add-apt-repository -y ppa:nginx/stable

# Install Nginx & PHP
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    cron \
    re2c \
    composer \
    php7.0-curl \
    php7.0-dev \
    php7.0-fpm \
    php7.0-gd \
    php7.0-gearman \
    php7.0-geoip \
    php7.0-imagick \
    php7.0-intl \
    php7.0-json \
    php7.0-ldap \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-memcache \
    php7.0-memcached \
    php7.0-mongodb \
    php7.0-mysql \
    php7.0-pgsql \
    php7.0-redis \
    php7.0-sqlite3 \
    php7.0-xmlrpc \    
    php-xdebug \
    nginx \
    supervisor \
    libyaml-dev \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    npm

#    php7.0-xcache \

RUN apt-get install php-yaml

RUN git clone https://github.com/phalcon/zephir.git && \
    cd zephir && \
    ./install -c && \
    cd ..

RUN git clone https://github.com/phalcon/cphalcon.git && \
    cd cphalcon && \
    git checkout 3.1.x && \
    zephir build --backend=ZendEngine3 && \
    cd .. && \
    echo 'extension=phalcon.so' > /etc/php/7.0/mods-available/phalcon.ini && \
    ln -s /etc/php/7.0/mods-available/phalcon.ini /etc/php/7.0/cli/conf.d/50-phalcon.ini && \
    ln -s /etc/php/7.0/mods-available/phalcon.ini /etc/php/7.0/fpm/conf.d/50-phalcon.ini

RUN rm -rf cphalcon && rm -rf zephir

RUN apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer & support parallel install
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN composer global require hirak/prestissimo

# Npm
RUN ln -fs /usr/bin/nodejs /usr/local/bin/node
RUN npm config set registry http://registry.npmjs.org/
RUN npm config set strict-ssl false
RUN npm install -g bower grunt-cli gulp-cli

# Nginx & PHP configuration
COPY conf/vhosts/* /etc/nginx/sites-available/
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/php.ini /etc/php/7.0/fpm/php.ini
COPY conf/cli.php.ini /etc/php/7.0/cli/php.ini
COPY conf/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf
COPY conf/www.conf /etc/php/7.0/fpm/pool.d/www.conf
COPY conf/certs/cert.pem /etc/nginx/certs/cert.pem
COPY conf/certs/key.pem /etc/nginx/certs/key.pem

# Enable vhosts
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/tiki.dev.conf /etc/nginx/sites-enabled/tiki.dev.conf
RUN ln -s /etc/nginx/sites-available/api.tiki.dev.conf /etc/nginx/sites-enabled/api.tiki.dev.conf
RUN ln -s /etc/nginx/sites-available/iapi.tiki.dev.conf /etc/nginx/sites-enabled/iapi.tiki.dev.conf
RUN ln -s /etc/nginx/sites-available/backend.tiki.dev.conf /etc/nginx/sites-enabled/backend.tiki.dev.conf

# Supervisord configuration
ADD conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
