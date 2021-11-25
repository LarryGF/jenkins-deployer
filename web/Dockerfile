FROM nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY ./config/jenkins.conf /etc/nginx/conf.d/jenkins.conf
COPY ./config/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx"]