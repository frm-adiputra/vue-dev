FROM frma/baseimage-nginx

# create user
RUN groupadd --gid {{GID}} -r devuser \
 && useradd --uid {{UID}} --create-home --home /home/devuser --system --gid devuser devuser \
 && usermod -aG www-data devuser

# modify nginx conf
RUN sed -i "s/user  nginx;/user devuser;/" /etc/nginx/nginx.conf \
 && sed -i "s~pid        /var/run/nginx.pid;~pid /var/run/{{UID}}/nginx.pid;~" /etc/nginx/nginx.conf

COPY default.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /var/run/{{UID}} \
 && chown -R devuser:devuser /var/run/{{UID}} \
 && chown -R devuser:devuser /var/log/nginx \
 && chown -R devuser:devuser /var/cache/nginx/

USER devuser
