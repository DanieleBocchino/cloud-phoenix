FROM node:8.11.1

WORKDIR /src/app

RUN git clone https://github.com/claranet-ch/cloud-phoenix-kata.git /start

COPY /app/package*.json ./

RUN npm install

COPY /app/ ./ 

CMD ["npm", "start"]