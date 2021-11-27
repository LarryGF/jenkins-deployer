FROM nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY ./config/endpoints.conf /etc/nginx/conf.d/endpoints.conf
COPY ./config/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx"]