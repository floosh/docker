FROM alpine:3.5

# Install dependencies
RUN apk add --no-cache php7-session php7-mysqli php7-mbstring php7-xml php7-gd php7-zlib php7-bz2 php7-zip php7-openssl php7-curl php7-opcache php7-json nginx php7-fpm supervisor

# Include keyring to verify download
COPY phpmyadmin.keyring /

# Copy configuration
COPY etc /etc/

# Copy main script
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

# File upload size
RUN sed -i -e "s/^upload_max_filesize\s*=\s*2M/upload_max_filesize = 256M/" /etc/php5/php.ini
RUN sed -i -e "s/^post_max_size\s*=\s*8M/post_max_size = 256M/" /etc/php5/php.ini

# Calculate download URL
ENV VERSION 4.6.5.2
ENV URL https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.gz
LABEL version=$VERSION

# Download tarball, verify it using gpg and extract
RUN set -x \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && apk add --no-cache curl gnupg \
    && curl --output phpMyAdmin.tar.gz --location $URL \
    && curl --output phpMyAdmin.tar.gz.asc --location $URL.asc \
    && gpgv --keyring /phpmyadmin.keyring phpMyAdmin.tar.gz.asc phpMyAdmin.tar.gz \
    && apk del --no-cache curl gnupg \
    && rm -rf "$GNUPGHOME" \
    && tar xzf phpMyAdmin.tar.gz \
    && rm -f phpMyAdmin.tar.gz phpMyAdmin.tar.gz.asc \
    && mv phpMyAdmin-$VERSION-all-languages /www \
    && mv /www/doc/html /www/htmldoc \
    && rm -rf /www/doc \
    && mkdir /www/doc \
    && mv /www/htmldoc /www/doc/html \
    && rm /www/doc/html/.buildinfo /www/doc/html/objects.inv \
    && rm -rf /www/js/jquery/src/ /www/js/openlayers/src/ /www/setup/ /www/examples/ /www/test/ /www/po/ /www/templates/test/ /www/phpunit.xml.* /www/build.xml  /www/composer.json /www/RELEASE-DATE-$VERSION \
    && sed -i "s@define('CONFIG_DIR'.*@define('CONFIG_DIR', '/etc/phpmyadmin/');@" /www/libraries/vendor_config.php \
    && chown -R root:nobody /www \
    && find /www -type d -exec chmod 750 {} \; \
    && find /www -type f -exec chmod 640 {} \;

# Add volume for sessions to allow session persistence
VOLUME /sessions

# We expose phpMyAdmin on port 80
EXPOSE 80

ENTRYPOINT [ "/run.sh" ]
CMD ["phpmyadmin"]
