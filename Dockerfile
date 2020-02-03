FROM buildpack-deps:jessie

# skip installing gem documentation
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 1.8
ENV RUBY_VERSION 1.8.7-p374
ENV RUBY_DOWNLOAD_SHA256 0c4e000253ef7187feeb940a01a1c7594f28d63aa16f978e892a0e2864f58614
ENV RUBYGEMS_VERSION 3.0.3

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \

	apt-get update; \
	apt-get install -y --no-install-recommends \
    libmysqlclient-dev \
    libxslt1-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    imagemagick \
    libmagick++-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    libc6-dev \
    make gcc \
    subversion \
    byacc \
    sudo \
		autoconf \
		wget \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.gz"; \
	# gen # echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; \
	\
	mkdir -p /usr/src/ruby; \
	tar -xvf ruby.tar.gz -C /usr/src/ruby --strip-components=1; \
	rm ruby.tar.gz; \
	\
	cd /usr/src/ruby; \
	\
	autoconf; \
	# echo $DEB_BUILD_GNU_TYPE \
	# gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		# --build=amd64 \
		--disable-install-doc \
		--enable-shared \
	; \
	make; \
	make install; \

	mkdir -p /usr/src/rubygems; \
	cd /; \
	wget -O rubygems.tgz "https://rubygems.org/rubygems/rubygems-2.4.8.tgz"; \
	tar -xvf rubygems.tgz -C /usr/src/rubygems --strip-components=1; \
	rm rubygems.tgz; \
	cd /usr/src/rubygems; \
	ruby setup.rb; \
	cd /; \
	rm -r /usr/src/rubygems; \
	gem install bundler -v 1.17.3; \
	\
	apt-get remove -y --no-install-recommends ruby; \

	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	export SUDO_FORCE_REMOVE=yes; \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	cd /; \
	rm -r /usr/src/ruby; \

	ruby --version; \
	gem --version; \
	bundle --version

# don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

CMD [ "irb" ]
