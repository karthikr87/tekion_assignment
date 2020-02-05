FROM node:8.10.0-alpine
EXPOSE 5000 9095
COPY espm-ui-cf espm-ui-cf/
WORKDIR ./espm-ui-cf

CMD ["node", "./node_modules/@sap/approuter/approuter.js"]