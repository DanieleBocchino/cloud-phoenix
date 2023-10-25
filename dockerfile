FROM node:8.11.1

WORKDIR /app

RUN git clone https://github.com/claranet-ch/cloud-phoenix-kata.git .

RUN npm install

EXPOSE 3000

CMD ["npm", "start"]
