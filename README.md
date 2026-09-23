# NovaLink C.A. - Central VoIP (Asterisk PBX)

Este repositorio contiene la infraestructura y configuraciones necesarias para desplegar la central telefónica VoIP de NovaLink C.A. utilizando Asterisk 20 sobre contenedores Docker.

## Instrucciones de Despliegue

El despliegue del servidor consta de dos pasos fundamentales: la construcción de la imagen (donde se compila Asterisk desde su código fuente y se autogeneran los certificados TLS) y la ejecución del contenedor.

### 1. Construir la Imagen (Build)

Para construir la imagen de Docker, debes pasar tu dirección IP (la de ZeroTier o tu IP pública/local) como argumento. Esto es necesario para que el sistema autogenere los certificados criptográficos (`.crt` y `.key`) a nombre de tu servidor.

Ejecuta el siguiente comando en la terminal, asegurándote de estar en la carpeta donde se encuentra el archivo `Dockerfile`:

```bash
docker build --build-arg PBX_IP=<TU_DIRECCION_IP> -t asterisk-novalink .
```
*(Nota: Reemplaza `<TU_DIRECCION_IP>` por la IP correspondiente a tu servidor y no olvides el punto `.` al final del comando).*

### 2. Iniciar el Contenedor (Run)

Una vez construida la imagen (bautizada como `asterisk-novalink`), encenderemos el servidor. 

Para mantener la infraestructura inmutable, inyectaremos en tiempo real los 5 archivos de configuración básicos directamente desde una carpeta local de nuestra computadora hacia el contenedor utilizando Volúmenes (`-v`). Esto evitará que se sobrescriban los cientos de archivos base de Asterisk.

Asegúrate de tener una carpeta local (por ejemplo `mi-configuracion`) con tus archivos listos y ejecuta el siguiente comando:

```bash
docker run -d \
  --name pbx-nova \
  --net host \
  -v $(pwd)/<TU_CARPETA>/pjsip.conf:/etc/asterisk/pjsip.conf \
  -v $(pwd)/<TU_CARPETA>/extensions.conf:/etc/asterisk/extensions.conf \
  -v $(pwd)/<TU_CARPETA>/logger.conf:/etc/asterisk/logger.conf \
  -v $(pwd)/<TU_CARPETA>/rtp.conf:/etc/asterisk/rtp.conf \
  -v $(pwd)/<TU_CARPETA>/confbridge.conf:/etc/asterisk/confbridge.conf \
  asterisk-novalink
```

**Nota sobre la ruta:** 
- El comando asume el uso de `$(pwd)` para obtener dinámicamente la ruta actual. Debes ejecutar el comando situado exactamente afuera de tu carpeta de configuración.
- Reemplaza `<TU_CARPETA>` por el nombre real de tu directorio local (ej. `config-sede1`).

### Mantenimiento (Recarga en caliente)

Gracias al uso de Volúmenes, si modificas los archivos dentro de tu carpeta local usando cualquier editor de texto, los cambios se reflejarán inmediatamente dentro del contenedor. 

Para que Asterisk aplique los cambios sin apagar el servidor, simplemente ingresa a la consola ejecutando:
- Para actualizar el Dialplan (extensions.conf): `docker exec pbx-nova asterisk -rx "dialplan reload"`
- Para actualizar Usuarios y Troncales (pjsip.conf): `docker exec pbx-nova asterisk -rx "pjsip reload"`
