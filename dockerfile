FROM node:8.11.1

WORKDIR /src/app

RUN git clone https://github.com/claranet-ch/cloud-phoenix-kata.git .

RUN npm install

COPY . /src/app/

CMD ["npm", "start"]

# docker build -t name_image -f Dockerfile .
 