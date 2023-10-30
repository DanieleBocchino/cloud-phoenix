FROM node:8.11.1

WORKDIR /src/app

COPY ./app/ .

RUN npm install

#RUN wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

CMD ["npm", "start"]