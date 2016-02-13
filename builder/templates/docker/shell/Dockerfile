FROM frma/baseimage-vue

RUN npm install -g bower

RUN groupadd --gid {{GID}} -r devuser \
 && useradd --uid {{UID}} --create-home --home /home/devuser --system --gid devuser devuser

USER devuser
