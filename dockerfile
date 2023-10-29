# Usa l'immagine di Node.js 8.11.1 LTS
FROM node:8.11.1

WORKDIR /src/app

COPY ./app/package*.json /src/app/

RUN npm install

COPY ./app/ /src/app/

VOLUME ["/src/app"]

CMD [ "npm", "start" ]
