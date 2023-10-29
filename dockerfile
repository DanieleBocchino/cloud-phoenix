FROM node:8.11.1

WORKDIR /app

COPY ./app/package*.json /app/

RUN npm install

COPY ./app/ /app/

EXPOSE 3000

CMD ["npm", "start"]
