FROM node:22-alpine
WORKDIR /app/api
COPY api/package*.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY api/src ./src
COPY api/test ./test
COPY db /app/db
COPY web /app/web
USER node
EXPOSE 3000
CMD ["node","src/server.js"]
