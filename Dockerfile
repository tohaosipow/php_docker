FROM php:8.0-fpm

RUN apt-get update
RUN apt-get install -y nginx


RUN curl -sS https://getcomposer.org/installer | php && \
mv composer.phar /usr/local/bin/composer

RUN apt-get install -y git unzip zip libxslt-dev
RUN apt-get install -y \
        libzip-dev \
        librabbitmq-dev \
        zip \
  && docker-php-ext-install zip

RUN apt-get install -y supervisor
RUN pecl install redis
RUN docker-php-ext-enable redis
RUN pecl install amqp
RUN docker-php-ext-enable amqp
RUN docker-php-ext-install sockets
RUN docker-php-ext-install xsl mysqli pdo pdo_mysql
RUN docker-php-ext-install opcache
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install bcmath
RUN apt-get update --fix-missing

RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd


RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

WORKDIR /var/www
COPY composer.json /var/www
COPY composer.lock /var/www
RUN composer install --no-dev --no-interaction --no-autoloader --no-scripts

COPY . /var/www
RUN composer dump-autoload --optimize
COPY nginx.conf /etc/nginx/sites-available/default
RUN chmod -R 777 ./storage
RUN chown -R www-data:www-data /var/www
RUN php artisan storage:link


EXPOSE 80
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php artisan cache:clear && php artisan migrate --force && /usr/bin/supervisord
