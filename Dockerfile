FROM ubuntu:14.04.3
MAINTAINER Hoa Nguyen <hoa.nguyenmanh@tiki.vn>

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Setup timezone & install libraries
RUN echo "Asia/Bangkok" > /etc/timezone \
&& dpkg-reconfigure -f noninteractive tzdata \
&& apt-get install -y software-properties-common \
&& apt-get install -y language-pack-en-base \
&& add-apt-repository -y ppa:nginx/stable \
&& add-apt-repository -y ppa:ondrej/php \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    libpcre3-dev \
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
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/php5/cli/conf.d/20-xdebug.ini /etc/php5/fpm/conf.d/20-xdebug.ini
# Disable xdebug by default

# Install nodejs, npm, phalcon & composer
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - \
&& apt-get install -y nodejs \
&& git clone -b 1.3.6 https://github.com/phalcon/cphalcon.git \
&& cd cphalcon/build && ./install \
&& echo "extension=phalcon.so" > /etc/php/5.6/mods-available/phalcon.ini \
&& /usr/sbin/phpenmod phalcon \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm cache clean \
&& npm install -g bower grunt-cli gulp-cli

# Nginx & PHP configuration
COPY start.sh /start.sh
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf
COPY conf/nginx/certs /etc/nginx/certs
COPY conf/nginx/vhosts/* /etc/nginx/sites-available/
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php56/php.ini /etc/php/5.6/fpm/php.ini
COPY conf/php56/cli.php.ini /etc/php/5.6/cli/php.ini
COPY conf/php56/php-fpm.conf /etc/php/5.6/fpm/php-fpm.conf
COPY conf/php56/www.conf /etc/php/5.6/fpm/pool.d/www.conf
COPY conf/php56/xdebug.ini /etc/php/5.6/mods-available/xdebug.ini

# Configure vhosts & bootstrap script && forward request and error logs to docker log collector
RUN rm -f /etc/nginx/sites-enabled/default \
&& ln -sf /etc/nginx/sites-available/tiki.dev.conf /etc/nginx/sites-enabled/tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/api.tiki.dev.conf /etc/nginx/sites-enabled/api.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/apiv2.tiki.dev.conf /etc/nginx/sites-enabled/apiv2.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/iapi.tiki.dev.conf /etc/nginx/sites-enabled/iapi.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/aapi.tiki.dev.conf /etc/nginx/sites-enabled/aapi.tiki.dev.conf \
&& ln -sf /etc/nginx/sites-available/backend.tiki.dev.conf /etc/nginx/sites-enabled/backend.tiki.dev.conf \
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log \
&& chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
