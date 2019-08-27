FROM ubuntu:18.04
MAINTAINER Hoa Nguyen <hoa.nguyenmanh@tiki.vn>

WORKDIR /src

RUN apt-get clean && apt-get update && apt-get install -y locales && apt-get install -y tzdata

# Environment for php7.1-phalcon build
ENV DEBIAN_FRONTEND noninteractive

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Setup timezone & install libraries
RUN echo "Asia/Bangkok" > /etc/timezone \
&& dpkg-reconfigure -f noninteractive tzdata \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common language-pack-en-base wget curl \
&& add-apt-repository -y ppa:nginx/stable \
&& add-apt-repository -y ppa:ondrej/php \
&& echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' > /etc/apt/sources.list.d/newrelic.list \
&& curl -sSL https://download.newrelic.com/548C16BF.gpg | apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    sudo \
    libpcre3-dev \
    vim \
    dialog \
    net-tools \
    git \
    zip \
    unzip \
    supervisor \
    nginx \
    php7.1-cli \
    php7.1-dev \
    php7.1-fpm \
    php7.1-bcmath \
    php7.1-bz2 \
    php7.1-zip \
    php7.1-dba \
    php7.1-dom \
    php7.1-curl \
    php7.1-gd \
    php7.1-geoip \
    php7.1-imagick \
    php7.1-json \
    php7.1-ldap \
    php7.1-mbstring \
    php7.1-mcrypt \
    php7.1-memcache \
    php7.1-memcached \
    php7.1-mongo \
    php7.1-mongodb \
    php7.1-mysqlnd \
    php7.1-pgsql \
    php7.1-redis \
    php7.1-soap \
    php7.1-sqlite \
    php7.1-xml \
    php7.1-xmlrpc \
    php7.1-xdebug \
    php7.1-intl \
    php7.1-apcu \
    php7.1-apcu-bc \
    newrelic-php5 \
&& phpdismod xdebug newrelic \
&& (curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-bionic-td-agent3.sh | sh) \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Disable xdebug by default

# Install php-lz4
RUN git clone --recursive --depth=1 https://github.com/kjdev/php-ext-lz4.git \
    && cd php-ext-lz4 \
    && phpize \
    && ./configure && make && make install \
    && echo "extension=lz4.so" > /etc/php/7.1/mods-available/lz4.ini \
    && phpenmod lz4 \
    && cd .. && rm -rf php-ext-lz4

# Install php-snappy
RUN git clone -b 0.1.9 --recursive --depth=1 https://github.com/kjdev/php-ext-snappy.git \
    && cd php-ext-snappy \
    && phpize \
    && ./configure && make && make install \
    && echo "extension=snappy.so" > /etc/php/7.1/mods-available/snappy.ini \
    && phpenmod snappy \
    && cd .. && rm -rf php-ext-snappy

# Install php-rdkafka
RUN curl -sSL https://github.com/edenhill/librdkafka/archive/v1.1.0.tar.gz | tar xz \
    && cd librdkafka-1.1.0 \
    && ./configure && make && make install \
    && cd .. && rm -rf librdkafka-1.1.0

RUN curl -sSL https://github.com/arnaud-lb/php-rdkafka/archive/3.1.2.tar.gz | tar xz \
    && cd php-rdkafka-3.1.2 \
    && phpize && ./configure && make all && make install \
    && echo "extension=rdkafka.so" > /etc/php/7.1/mods-available/rdkafka.ini \
    && phpenmod rdkafka \
    && cd .. && rm -rf php-rdkafka-3.1.2

# Install php-ext-zstd
RUN git clone --recursive --depth=1 https://github.com/kjdev/php-ext-zstd.git \
    && cd php-ext-zstd \
    && phpize && ./configure && make && make install \
    && echo "extension=zstd.so" > /etc/php/7.1/mods-available/zstd.ini \
    && phpenmod zstd \
    && cd .. && rm -rf php-ext-zstd

# Runkit7 https://github.com/runkit7/runkit7
RUN curl -sSL https://github.com/runkit7/runkit7/releases/download/1.0.5a4/runkit-1.0.5a4.tgz | tar xz \
    && cd runkit-1.0.5a4 \
    && phpize && ./configure && make all && make install \
    && echo "extension=runkit.so" > /etc/php/7.1/mods-available/runkit.ini \
    && phpenmod runkit \
    && cd .. && rm -rf runkit-1.0.5a4

# Install nodejs, npm, phalcon & composer
RUN  curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash \
&& apt-get install -y php7.1-phalcon \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& curl -sL https://deb.nodesource.com/setup_8.x | bash - \
&& apt-get install -y nodejs \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm install -g bower grunt-cli gulp-cli

RUN npm i -g aglio --unsafe-perm=true --allow-root

# Nginx & PHP configuration
COPY start.sh /start.sh
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf
COPY conf/td-agent/td-agent.conf /etc/td-agent/td-agent.conf
COPY conf/nginx/certs /etc/nginx/certs
COPY conf/nginx/vhosts/* /etc/nginx/sites-available/
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php71/php.ini /etc/php/7.1/fpm/php.ini
COPY conf/php71/cli.php.ini /etc/php/7.1/cli/php.ini
COPY conf/php71/php-fpm.conf /etc/php/7.1/fpm/php-fpm.conf
COPY conf/php71/www.conf /etc/php/7.1/fpm/pool.d/www.conf
COPY conf/php71/xdebug.ini /etc/php/7.1/fpm/pool.d/xdebug.ini

# Configure php & vhosts & bootstrap scripts && forward request and error logs to docker log collector
RUN rm -f /etc/nginx/sites-enabled/default \
&& mkdir /run/php \
&& chown www-data:www-data /run/php \
&& ln -sf /etc/nginx/sites-available/tiki.conf /etc/nginx/sites-enabled/tiki.conf \
&& ln -sf /etc/nginx/sites-available/api.tiki.conf /etc/nginx/sites-enabled/api.tiki.conf \
&& ln -sf /etc/nginx/sites-available/apiv2.tiki.conf /etc/nginx/sites-enabled/apiv2.tiki.conf \
&& ln -sf /etc/nginx/sites-available/iapi.tiki.conf /etc/nginx/sites-enabled/iapi.tiki.conf \
&& ln -sf /etc/nginx/sites-available/backend.tiki.conf /etc/nginx/sites-enabled/backend.tiki.conf \
&& ln -sf /etc/nginx/sites-available/oms.tiki.conf /etc/nginx/sites-enabled/oms.tiki.conf \
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log \
&& chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
