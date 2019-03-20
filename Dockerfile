FROM ubuntu:xenial

LABEL maintainer "srz_zumix <https://github.com/srz-zumix>"

# ENV DEBCONF_NOWARNINGS yes

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update -q -y && \
    apt-get install -y --no-install-recommends software-properties-common && \
    apt-get update -q -y && \
    apt-get install -y --no-install-recommends \
        apt-transport-https ca-certificates \
        git build-essential curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && \
    apt-get update -q -y && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -q -y && \
    apt-get install -y --no-install-recommends yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# RUN yarn global add codecrumbs
RUN mkdir /codecrumbs && \
    git clone https://github.com/Bogdan-Lyashenko/codecrumbs.git /codecrumbs
COPY webpack.prod.js /codecrumbs/src/public
WORKDIR /codecrumbs
RUN find ./src/server -type f -name '*.js' -print0 | xargs -0 grep -l '127.0.0.1' | xargs sed -i.bak -e 's/127\.0\.0\.1/0.0.0.0/g' && \
    sed -i.bak -e 's|createConnection(\(.*\));|createConnection(\1, `ws://${window.location.hostname}:3018/`);|g' ./src/public/js/core/dataBus/index.js
    # sed -i.bak -e 's|createConnection(\(.*\));|createConnection(\1, `ws://${window.location.hostname}:${SERVER_PORT}/`);|g' ./src/public/js/core/dataBus/index.js && \    
    # sed -i.bak -e 's|import { SOCKET_MESSAGE_TYPE }.*|const { SERVER_PORT, SOCKET_MESSAGE_TYPE } = require("../../../../shared/constants");\n|g' ./src/public/js/core/dataBus/index.js
    # sed -i.bak -e 's|\(^.*setupLocal()\s*{\)|\1\n    const { SERVER_PORT, SOCKET_MESSAGE_TYPE } = require("../../../../shared/constants");|g' ./src/public/js/core/dataBus/index.js
RUN yarn && yarn run build && \
    yarn global add /codecrumbs

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
