FROM php:8.2-apache

ARG USER=docker
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get install -y \
    git zip apt-utils zlib1g-dev libpng-dev libzip-dev default-mysql-client

RUN docker-php-ext-install mysqli pdo pdo_mysql gd zip

#INSTALL COMPOSER
RUN set -xe \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

#INSTALL PHP-CS-FIXER
RUN set -xe \
    && curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o php-cs-fixer \
    && chmod +x php-cs-fixer \
    && mv php-cs-fixer /usr/bin/php-cs-fixer \
    && echo "alias fix='php-cs-fixer fix'" >> /etc/bash.bashrc

#INSTALL PHP-DOC
RUN set -xe \
    && curl -L https://phpdoc.org/phpDocumentor.phar -o phpDocumentor.phar \
    && chmod +x phpDocumentor.phar \
    && mv phpDocumentor.phar /usr/bin/phpdoc \
    && echo "alias phpdoc_all='phpdoc -d /home/${USER} -t /home/${USER}/documentation --ignore \"vendor/\"'" >> /etc/bash.bashrc

RUN echo "alias build='php artisan migrate:fresh && php artisan db:seed'" >> /etc/bash.bashrc
RUN echo "alias pest='./vendor/bin/pest'" >> /etc/bash.bashrc

#APACHE CONFIG
ENV APACHE_DOCUMENT_ROOT /home/${USER}
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN a2enmod rewrite

ENV TZ=America/Argentina/Buenos_Aires
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo 'memory_limit = 9000M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;
RUN echo 'max_execution_time = 12000' >> /usr/local/etc/php/conf.d/docker-php-maxexectime.ini;
RUN echo 'date.timezone = "${TZ}"' >> /usr/local/etc/php/conf.d/docker-php-datetimezone.ini;

### SETUP CURRENT USER ###
RUN useradd -m ${USER} --uid=${USER_UID} | chpasswd
USER ${USER_UID}:${USER_GID}
WORKDIR /home/${USER}

CMD php artisan serve --port=80 --host=0.0.0.0

