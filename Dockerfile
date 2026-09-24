FROM ghcr.io/cirruslabs/flutter:3.47.5 AS build

WORKDIR /app
COPY . .

RUN rm -rf /tmp/agenda_base && \
    flutter create --project-name agenda_per_anna --org com.riccardopinato --platforms=web /tmp/agenda_base && \
    cp -R /tmp/agenda_base/web . && \
    cp web_manifest.json web/manifest.json && \
    sed -i "s#<title>agenda_per_anna</title>#<title>Anna's Diary</title>#g" web/index.html && \
    sed -i "s#content=\"agenda_per_anna\"#content=\"Anna's Diary\"#g" web/index.html && \
    mkdir -p assets/icon && \
    base64 -d assets/icon/app_icon.b64 > assets/icon/app_icon.jpg && \
    sed -i 's#assets/icon/app_icon.png#assets/icon/app_icon.jpg#g' pubspec.yaml && \
    flutter pub get --enforce-lockfile && \
    flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
