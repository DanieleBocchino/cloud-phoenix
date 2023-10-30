FROM node:8.11.1

WORKDIR /src/app

COPY ./app/ .

RUN npm install

CMD ["npm", "start"]