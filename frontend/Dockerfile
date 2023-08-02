# syntax=docker/dockerfile:1
FROM node:12.22
WORKDIR cansat
RUN npm install
EXPOSE 3000
COPY . .
CMD ["npm", "start"]
