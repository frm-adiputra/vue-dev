FROM frma/baseimage-vue

RUN groupadd --gid {{GID}} -r devuser \
 && useradd --uid {{UID}} --create-home --home /home/devuser --system --gid devuser devuser

USER devuser
WORKDIR /home/devuser/src/{{PROJECT}}

ENV PATH="/home/devuser/src/{{PROJECT}}/node_modules/.bin:$PATH"

CMD ["/bin/bash"]