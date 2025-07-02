# Use official PHP with Apache image
FROM php:7.4-apache

# Install mysqli extension
RUN docker-php-ext-install mysqli

# Copy app code to Apache web root
COPY . /var/www/html/

# Expose port 80
EXPOSE 80
