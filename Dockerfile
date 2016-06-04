FROM ubuntu:14.04.3

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Setup timezone & install libraries
RUN echo "Asia/Bangkok" > /etc/timezone \
&& dpkg-reconfigure -f noninteractive tzdata \
&& apt-get install -y software-properties-common \
&& add-apt-repository -y ppa:nginx/stable && add-apt-repository -y ppa:ondrej/php5-5.6 \
&& apt-get update && apt-get install -y \
    build-essential \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    supervisor \
    nginx \
    php5-dev \
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
    php5-xdebug \
    php5-intl \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/php5/cli/conf.d/20-xdebug.ini /etc/php5/fpm/conf.d/20-xdebug.ini
# Disable xdebug by default

# Install nodejs, npm, phalcon & composer
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash - \
&& apt-get install -y nodejs \
&& git clone -b 1.3.6 https://github.com/phalcon/cphalcon.git \
&& cd cphalcon/build && ./install \
&& echo "extension=phalcon.so" >> /etc/php5/mods-available/phalcon.ini \
&& php5enmod phalcon \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& composer global require hirak/prestissimo \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm install -g npm bower grunt-cli gulp-cli

# Nginx & PHP configuration
COPY start.sh /start.sh
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf
COPY conf/nginx/certs /etc/nginx/certs
COPY conf/nginx/vhosts/* /etc/nginx/sites-available/
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php/php.ini /etc/php5/fpm/php.ini
COPY conf/php/cli.php.ini /etc/php5/cli/php.ini
COPY conf/php/php-fpm.conf /etc/php5/fpm/php-fpm.conf
COPY conf/php/www.conf /etc/php5/fpm/pool.d/www.conf
COPY conf/php/xdebug.ini /etc/php5/mods-available/xdebug.ini

# Configure vhosts & bootstrap script && forward request and error logs to docker log collector
RUN rm -f /etc/nginx/sites-enabled/default \
&& ln -sf /etc/nginx/sites-available/tiki.dev.conf /etc/nginx/sites-enabled/tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/api.tiki.dev.conf /etc/nginx/sites-enabled/api.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/apiv2.tiki.dev.conf /etc/nginx/sites-enabled/apiv2.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/iapi.tiki.dev.conf /etc/nginx/sites-enabled/iapi.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/backend.tiki.dev.conf /etc/nginx/sites-enabled/backend.tiki.dev.conf \
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log \
&& chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
