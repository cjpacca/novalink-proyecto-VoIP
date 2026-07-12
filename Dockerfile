# Usamos Ubuntu como sistema base
FROM ubuntu:22.04

# Evitamos interacciones manuales (como selección de zona horaria) durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalamos dependencias del sistema requeridas por Asterisk
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    pkg-config \
    libedit-dev \
    uuid-dev \
    libjansson-dev \
    libxml2-dev \
    sqlite3 \
    libsqlite3-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Copiamos el código fuente que ya descargaste hacia dentro del contenedor
# Nota: Ajustamos el comodín para que coincida con la carpeta de Asterisk 20
COPY ./src/asterisk-20*/ /usr/src/asterisk/

# 3. Compilamos Asterisk (Preparación, Make y Make Install)
WORKDIR /usr/src/asterisk
RUN ./configure
RUN make menuselect.makeopts
RUN make
RUN make install
# Instalamos los archivos de configuración de muestra básicos
RUN make samples 

# 4. Exponemos los puertos necesarios para la señalización (SIP) y los medios (RTP)
EXPOSE 5060/udp 5060/tcp
EXPOSE 10000-20000/udp

# 5. Comando por defecto para iniciar Asterisk en primer plano (foreground) para que el contenedor no se apague
CMD ["/usr/sbin/asterisk", "-f"]
