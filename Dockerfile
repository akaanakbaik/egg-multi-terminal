FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
ENV USER=container
ENV HOME=/home/container
ENV TERM=xterm-256color
ENV NVM_DIR=/usr/local/nvm
ENV BUN_INSTALL=/usr/local/bun
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PATH=/opt/pytools/bin:/usr/local/bun/bin:${PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      apt-utils \
      ca-certificates \
      curl \
      wget \
      git \
      git-lfs \
      unzip \
      zip \
      tar \
      xz-utils \
      gzip \
      bzip2 \
      gnupg \
      jq \
      yq \
      nano \
      vim-tiny \
      htop \
      tmux \
      screen \
      sudo \
      locales \
      tzdata \
      procps \
      psmisc \
      lsof \
      iproute2 \
      iputils-ping \
      dnsutils \
      net-tools \
      telnet \
      openssh-client \
      rsync \
      sqlite3 \
      redis-tools \
      postgresql-client \
      mariadb-client \
      build-essential \
      gcc \
      g++ \
      gdb \
      clang \
      clang-format \
      cmake \
      make \
      pkg-config \
      autoconf \
      automake \
      libtool \
      python3 \
      python3-pip \
      python3-venv \
      python3-dev \
      pipx \
      php-cli \
      php-common \
      php-curl \
      php-mbstring \
      php-xml \
      php-zip \
      php-sqlite3 \
      php-mysql \
      php-pgsql \
      php-bcmath \
      php-gd \
      php-intl \
      php-soap \
      openjdk-21-jdk-headless \
      golang-go \
      ffmpeg \
      imagemagick \
      fonts-dejavu \
      libnss3 \
      libatk-bridge2.0-0 \
      libgtk-3-0 \
      libx11-xcb1 \
      libxcomposite1 \
      libxdamage1 \
      libxrandr2 \
      libgbm1 \
      libasound2t64 \
    && locale-gen en_US.UTF-8 id_ID.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN mkdir -p "${NVM_DIR}" \
    && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && source "${NVM_DIR}/nvm.sh" \
    && nvm install 18 \
    && nvm install 20 \
    && nvm install 22 \
    && nvm install node \
    && nvm alias default 22 \
    && nvm use default \
    && npm install -g npm@latest pm2@latest yarn@latest pnpm@latest nodemon@latest ts-node@latest typescript@latest vite@latest serve@latest http-server@latest wrangler@latest \
    && DEFAULT_BIN="$(dirname "$(nvm which default)")" \
    && for bin in node npm npx corepack pm2 pm2-dev pm2-docker pnpm pnpx yarn yarnpkg nodemon ts-node tsc vite serve http-server wrangler; do \
         if [[ -x "${DEFAULT_BIN}/${bin}" ]]; then ln -sf "${DEFAULT_BIN}/${bin}" "/usr/local/bin/${bin}"; fi; \
       done \
    && npm cache clean --force

RUN python3 -m venv /opt/pytools \
    && /opt/pytools/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel virtualenv \
    && /opt/pytools/bin/python -m pip install --no-cache-dir pipenv poetry uv yt-dlp requests aiohttp flask fastapi uvicorn gunicorn rich click

RUN curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm -f /tmp/composer-setup.php

RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in amd64) CF_ARCH="amd64" ;; arm64) CF_ARCH="arm64" ;; *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; esac \
    && curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}.deb" -o /tmp/cloudflared.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends /tmp/cloudflared.deb \
    && rm -f /tmp/cloudflared.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${BUN_INSTALL}" \
    && curl -fsSL https://bun.sh/install | bash \
    && chmod -R a+rx "${BUN_INSTALL}" \
    && ln -sf "${BUN_INSTALL}/bin/bun" /usr/local/bin/bun \
    && ln -sf "${BUN_INSTALL}/bin/bunx" /usr/local/bin/bunx

RUN curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh \
    && ln -sf /usr/local/bin/deno /usr/bin/deno

RUN set -eux; \
    install -d -m 0755 /home/container; \
    if getent group container >/dev/null; then \
      CONTAINER_GROUP=container; \
    elif getent group 1000 >/dev/null; then \
      OLD_GROUP="$(getent group 1000 | cut -d: -f1)"; \
      groupmod -n container "${OLD_GROUP}" || true; \
      CONTAINER_GROUP=container; \
    else \
      groupadd -g 1000 container || groupadd container; \
      CONTAINER_GROUP=container; \
    fi; \
    if id -u container >/dev/null 2>&1; then \
      usermod -d /home/container -s /bin/bash -g "${CONTAINER_GROUP}" container || true; \
    elif getent passwd 1000 >/dev/null; then \
      OLD_USER="$(getent passwd 1000 | cut -d: -f1)"; \
      usermod -l container "${OLD_USER}" || true; \
      usermod -d /home/container -s /bin/bash -g "${CONTAINER_GROUP}" container || true; \
    else \
      useradd -m -u 1000 -g "${CONTAINER_GROUP}" -s /bin/bash container || useradd -m -g "${CONTAINER_GROUP}" -s /bin/bash container; \
    fi; \
    usermod -d /home/container -s /bin/bash -g "${CONTAINER_GROUP}" container || true; \
    echo "container ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/container; \
    chmod 0440 /etc/sudoers.d/container; \
    install -d -o container -g "${CONTAINER_GROUP}" -m 0755 /home/container; \
    chown -R container:"${CONTAINER_GROUP}" /home/container /usr/local/nvm /opt/pytools /usr/local/bun || true

COPY scripts/aka-runtime.sh /etc/profile.d/aka-runtime.sh
COPY scripts/aka-info /usr/local/bin/aka-info
COPY scripts/aka-help /usr/local/bin/aka-help
COPY scripts/entrypoint.sh /usr/local/bin/aka-entrypoint

RUN chmod +x /usr/local/bin/aka-info /usr/local/bin/aka-help /usr/local/bin/aka-entrypoint \
    && chmod 0644 /etc/profile.d/aka-runtime.sh \
    && for version in 18 20 22; do \
         printf '%s\n' '#!/usr/bin/env bash' 'source /usr/local/nvm/nvm.sh' "exec nvm exec ${version} node \"\$@\"" > "/usr/local/bin/node${version}"; \
         printf '%s\n' '#!/usr/bin/env bash' 'source /usr/local/nvm/nvm.sh' "exec nvm exec ${version} npm \"\$@\"" > "/usr/local/bin/npm${version}"; \
         chmod +x "/usr/local/bin/node${version}" "/usr/local/bin/npm${version}"; \
       done

WORKDIR /home/container
USER container

ENTRYPOINT ["/usr/local/bin/aka-entrypoint"]
CMD ["bash"]
