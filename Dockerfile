FROM node:14-slim

RUN apt-get update && apt-get -y install procps

WORKDIR /app

COPY package.json /app
COPY package-lock.json /app

RUN npm install
RUN npm install -g mocha nodemon
RUN node -r esm util/approval.js

COPY . /app

RUN mkdir -p public/dist
RUN npm run build-client
RUN mkdir /app/secrets /app/logs /app/db

# Change this to our one-time-use API
RUN mv /app/accounts.js /app/secrets/
RUN mv /app/telegram.js /app/secrets/

EXPOSE 3000

CMD ["sh", "-c", "npm run start:${WHICHNET} ${KEYPW}"]
