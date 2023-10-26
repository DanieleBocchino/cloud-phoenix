FROM node:8.11.1

WORKDIR /app

RUN git clone https://github.com/claranet-ch/cloud-phoenix-kata.git .

RUN npm install

COPY . .

ENV PORT=3000
ENV DB_CONNECTION_STRING=mongodb://username:password@host:port/database

CMD ["npm", "start"]
 