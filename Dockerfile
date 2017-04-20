FROM ubuntu:14.04

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Setup timezone & install libraries
RUN echo "Asia/Bangkok" > /etc/timezone \
&& dpkg-reconfigure -f noninteractive tzdata \
&& apt-get update \
&& apt-get install -y software-properties-common \
&& add-apt-repository -y ppa:nginx/stable \
&& add-apt-repository -y ppa:ondrej/php \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    zip \
    unzip \
    supervisor \
    nginx \
    php5.6-cli \
    php5.6-dev \
    php5.6-fpm \
    php5.6-bcmath \
    php5.6-bz2 \
    php5.6-zip \
    php5.6-dba \
    php5.6-dom \
    php5.6-curl \
    php5.6-gd \
    php5.6-geoip \
    php5.6-imagick \
    php5.6-json \
    php5.6-ldap \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-memcache \
    php5.6-memcached \
    php5.6-mongo \
    php5.6-mongodb \
    php5.6-mysqlnd \
    php5.6-pgsql \
    php5.6-redis \
    php5.6-soap \
    php5.6-sqlite \
    php5.6-xml \
    php5.6-xmlrpc \
    php5.6-xcache \
    php5.6-xdebug \
    php5.6-intl \
&& echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' > /etc/apt/sources.list.d/newrelic.list \
&& curl -sSL https://download.newrelic.com/548C16BF.gpg | apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y newrelic-php5 \
&& /usr/sbin/phpdismod xdebug newrelic \
&& rm -rf /tmp/* /var/tmp/* \
&& rm -vf /var/cache/apt/*.bin /var/cache/apt/archives/*.* /var/lib/apt/lists/*.* \
&& apt-get autoclean
# Disable xdebug, newrelic by default

# Install nodejs, npm, phalcon & composer
RUN curl -sSL https://deb.nodesource.com/setup_6.x | sudo -E bash - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs \
&& git clone https://github.com/phalcon/cphalcon.git \
&& cd /cphalcon \
&& git checkout tags/phalcon-v2.0.13 \
&& cd build \
&& ./install 64bits \
&& echo "extension=phalcon.so" > /etc/php/5.6/mods-available/phalcon.ini \
&& /usr/sbin/phpenmod phalcon \
&& curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& composer global require hirak/prestissimo \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm install -g npm bower grunt-cli gulp-cli \
&& rm -rf /tmp/* /var/tmp/* \
&& rm -vf /var/cache/apt/*.bin /var/cache/apt/archives/*.* /var/lib/apt/lists/*.* \
&& apt-get autoclean

# Nginx & PHP configuration
COPY start.sh /start.sh
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf
COPY conf/nginx/certs /etc/nginx/certs
COPY conf/nginx/vhosts/* /etc/nginx/sites-available/
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php/php.ini /etc/php/5.6/fpm/php.ini
COPY conf/php/cli.php.ini /etc/php/5.6/cli/php.ini
COPY conf/php/php-fpm.conf /etc/php/5.6/fpm/php-fpm.conf
COPY conf/php/www.conf /etc/php/5.6/fpm/pool.d/www.conf
COPY conf/php/xdebug.ini /etc/php/5.6/mods-available/xdebug.ini

# Configure vhosts & bootstrap script && forward request and error logs to docker log collector
RUN rm -f /etc/nginx/sites-enabled/default \
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log \
&& chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
