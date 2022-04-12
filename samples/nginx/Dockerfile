# docker build -t nginx:tmp .
# docker run -p 3000:3000 nginx:tmp
# docker tag nginx:tmp asia-docker.pkg.dev/myproject/myregistry/myrepository:latest
# gcloud auth configure-docker asia-docker.pkg.dev --quiet
# docker push asia-docker.pkg.dev/myproject/myregistry/myrepository:latest

FROM nginx:stable

COPY ./nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
