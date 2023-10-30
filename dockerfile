FROM node:8.11.1

WORKDIR /src/app

COPY /app/package*.json ./

RUN npm install

COPY /app/ ./ 

CMD ["npm", "start"]