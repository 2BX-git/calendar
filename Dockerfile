FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3001
# Instala o curl
RUN apt update && apt install -y curl
# Copia o script de inicialização
COPY init.sh /app/init.sh
RUN chmod +x /app/init.sh
# Usa o script como entrypoint
ENTRYPOINT ["/app/init.sh"]
