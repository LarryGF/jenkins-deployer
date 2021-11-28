FROM nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY ./config/endpoints.conf.template /etc/nginx/templates/endpoints.conf.template
COPY ./config/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx"]