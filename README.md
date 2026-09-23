# NovaLink C.A. - Central VoIP (Asterisk PBX)

Este repositorio contiene la infraestructura y configuraciones necesarias para desplegar la central telefónica VoIP de NovaLink C.A. utilizando Asterisk 20 sobre contenedores Docker.

## Instrucciones de Despliegue

El despliegue del servidor consta de dos pasos fundamentales: la construcción de la imagen (donde se compila Asterisk desde su código fuente y se autogeneran los certificados TLS) y la ejecución del contenedor.

### 1. Construir la Imagen (Build)

Para construir la imagen de Docker, debes pasar tu dirección IP (la de ZeroTier o tu IP local) como argumento. Esto es necesario para que el sistema autogenere los certificados criptográficos (`.crt` y `.key`) a nombre de tu servidor.

Ejecuta el siguiente comando en la terminal, asegurándote de estar en la carpeta donde se encuentra el archivo `Dockerfile`:

```bash
docker build --build-arg PBX_IP=10.59.225.244 -t asterisk-novalink .
```
*(Nota: Reemplaza `10.59.225.244` por la IP que vayas a utilizar y no olvides el punto `.` al final del comando).*

### 2. Iniciar el Contenedor (Run)

Una vez construida la imagen (bautizada como `asterisk-novalink`), encenderemos el servidor. 

Para mantener la infraestructura inmutable, inyectaremos en tiempo real nuestros 5 archivos de configuración directamente desde la carpeta `config-sergio` de nuestra computadora hacia el contenedor utilizando Volúmenes (`-v`). Esto evitará que se sobrescriban los archivos base de Asterisk.

Ejecuta el siguiente comando:

```bash
docker run -d \
  --name pbx-nova \
  --net host \
  -v $(pwd)/config-sergio/pjsip.conf:/etc/asterisk/pjsip.conf \
  -v $(pwd)/config-sergio/extensions.conf:/etc/asterisk/extensions.conf \
  -v $(pwd)/config-sergio/logger.conf:/etc/asterisk/logger.conf \
  -v $(pwd)/config-sergio/rtp.conf:/etc/asterisk/rtp.conf \
  -v $(pwd)/config-sergio/confbridge.conf:/etc/asterisk/confbridge.conf \
  asterisk-novalink
```

**Nota sobre la ruta:** El comando anterior utiliza `$(pwd)` para obtener dinámicamente la ruta de la carpeta actual. Debes ejecutarlo estando situado dentro de la carpeta principal del proyecto (donde está la carpeta `config-sergio`).

### Mantenimiento (Recarga en caliente)

Gracias al uso de Volúmenes, si modificas los archivos dentro de la carpeta `config-sergio` usando tu editor de texto, el cambio se reflejará inmediatamente dentro del contenedor. 

Para que Asterisk aplique los cambios sin apagar el servidor, ejecuta:
- Para actualizar Dialplan (extensions.conf): `docker exec pbx-nova asterisk -rx "dialplan reload"`
- Para actualizar Usuarios/Troncales (pjsip.conf): `docker exec pbx-nova asterisk -rx "pjsip reload"`
