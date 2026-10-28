# NovaLink C.A. - Central Telefónica VoIP (Asterisk PBX)

Infraestructura de telecomunicaciones y configuraciones para desplegar la central telefónica VoIP corporativa de **NovaLink C.A.** utilizando **Asterisk 20** compilado desde código fuente sobre contenedores **Docker**, interconectada mediante **ZeroTier SD-WAN** y protegida con **SIP sobre TLS (puerto 5061)** y **SRTP (SDES)**.

---

## 📋 Tabla de Contenidos
1. [Requisitos Previos](#-requisitos-previos)
2. [Estructura del Proyecto](#-estructura-del-proyecto)
3. [Despliegue y Ejecución con Docker](#-despliegue-y-ejecución-con-docker)
4. [Comandos Esenciales de Gestión y CLI (Defensa en Vivo)](#-comandos-esenciales-de-gestión-y-cli-defensa-en-vivo)
5. [Configuración del Softphone (Linphone)](#-configuración-del-softphone-linphone)
6. [Plan de Numeración y Servicios PBX](#-plan-de-numeración-y-servicios-pbx)
7. [Interconexión Rápida con Otros Equipos (Sedes Externas)](#-interconexión-rápida-con-otros-equipos-sedes-externas)
8. [Resolución de Problemas Frecuentes (Troubleshooting)](#-resolución-de-problemas-frecuentes-troubleshooting)

---

## 🛠 Requisitos Previos

- **Sistema Operativo:** Linux (Ubuntu/Debian/Mint).
- **Docker Engine** instalado y con permisos de ejecución (`sudo usermod -aG docker $USER`).
- **ZeroTier** instalado y conectado a la red virtual compartida:
  ```bash
  # Verificar estado y red conectada
  sudo zerotier-cli listnetworks
  # Obtener la IP asignada en la interfaz ZeroTier (ej. 10.59.X.Y)
  ip addr show | grep 10.59
  ```
- **Softphone Linphone** instalado en los clientes de prueba.

---

## 📂 Estructura del Proyecto

```text
├── Dockerfile              # Definición de la imagen y compilación manual de Asterisk 20
├── config/                 # Configuraciones para la Sede 1 (Carlos - Rango 1XX)
│   ├── pjsip.conf          # Endpoints, transportes TLS/UDP, troncales y temporizadores
│   ├── extensions.conf     # Dialplan, reglas de marcado, salas de conferencia y eco
│   ├── rtp.conf            # Rango de puertos RTP (10000-10050) y timeouts
│   ├── confbridge.conf     # Parámetros de la sala de conferencia
│   └── logger.conf         # Configuración de logs y niveles de depuración
├── config-sergio/          # Configuraciones para la Sede 2 (Sergio - Rango 2XX)
├── keys/                   # Certificados criptográficos TLS (asterisk.crt y asterisk.key)
└── src/                    # Código fuente oficial de Asterisk 20 comprimido
```

---

## 🚀 Despliegue y Ejecución con Docker

### 1. Construir la Imagen (Build)

Para construir la imagen de Docker, puedes pasar opcionalmente tu dirección IP (la de ZeroTier o IP local) para la generación de certificados:

```bash
sudo docker build --build-arg PBX_IP=<TU_DIRECCION_IP> -t novalink .
```
*(Nota: Si no pasas el argumento, se construirá utilizando la configuración estándar).*

---

### 2. Iniciar el Contenedor (Run)

> **⚠️ IMPORTANTE:** Es fundamental utilizar el modo de red `--network host`. Esto permite que Asterisk se enlace directamente a la interfaz física y a la interfaz ZeroTier (`10.59.X.Y`), evitando que Docker aplique NAT interno (`172.17.X.X`), lo cual provocaría fallos de audio unidireccional en las cabeceras SDP de SIP.

#### Opción A: Montaje mediante Volúmenes (Recomendado para cambios en caliente)

**Para la Sede 1 (Carlos):**
```bash
sudo docker run -d \
  --name novalink \
  --network host \
  -v $(pwd)/config/pjsip.conf:/etc/asterisk/pjsip.conf \
  -v $(pwd)/config/extensions.conf:/etc/asterisk/extensions.conf \
  -v $(pwd)/config/logger.conf:/etc/asterisk/logger.conf \
  -v $(pwd)/config/rtp.conf:/etc/asterisk/rtp.conf \
  -v $(pwd)/config/confbridge.conf:/etc/asterisk/confbridge.conf \
  novalink
```

**Para la Sede 2 (Sergio):**
```bash
sudo docker run -d \
  --name novalink \
  --network host \
  -v $(pwd)/config-sergio/pjsip.conf:/etc/asterisk/pjsip.conf \
  -v $(pwd)/config-sergio/extensions.conf:/etc/asterisk/extensions.conf \
  -v $(pwd)/config-sergio/logger.conf:/etc/asterisk/logger.conf \
  -v $(pwd)/config-sergio/rtp.conf:/etc/asterisk/rtp.conf \
  -v $(pwd)/config-sergio/confbridge.conf:/etc/asterisk/confbridge.conf \
  novalink
```

#### Opción B: Iniciar sin volúmenes (Usa las copias internas del Dockerfile)
```bash
sudo docker run -d --name novalink --network host novalink
```

---

### 3. Control básico del contenedor
```bash
# Ver estado del contenedor
sudo docker ps

# Detener o iniciar el contenedor
sudo docker stop novalink
sudo docker start novalink

# Reiniciar el contenedor
sudo docker restart novalink

# Eliminar el contenedor
sudo docker rm -f novalink
```

---

## 💻 Comandos Esenciales de Gestión y CLI (Defensa en Vivo)

### Entrar a la Consola Interactiva de Asterisk (CLI)
Para observar el comportamiento en tiempo real con nivel alto de detalle (Verbose):
```bash
sudo docker exec -it novalink asterisk -rvvvvv
```
*(Para salir de la consola sin apagar Asterisk, escribe `exit` o `quit`).*

---

### Comandos Clave DENTRO de la Consola de Asterisk (`*CLI>`)

| Acción | Comando en consola | Explicación / Utilidad |
| :--- | :--- | :--- |
| **Ver extensiones activas** | `pjsip show endpoints` | Muestra si las extensiones (`101`, `102` / `201`, `202`) están `Available` / `In use`. |
| **Ver registros de ubicación** | `pjsip show aors` | Confirma las IPs y puertos desde donde se registraron los softphones. |
| **Ver estado de la troncal** | `pjsip show endpoint trunk-sede2` | Confirma si la conexión con la otra central está disponible. |
| **Monitorear señalización SIP en vivo** | `pjsip set logger on` | **Muestra todos los paquetes SIP (INVITE, 200 OK, BYE) en tiempo real.** |
| **Desactivar monitor SIP** | `pjsip set logger off` | Apaga la salida para no saturar la terminal. |
| **Ver llamadas activas en el instante** | `core show channels` | Muestra los canales y puentes (*bridges*) activos durante una llamada. |
| **Inspeccionar el Dialplan** | `dialplan show sedes_internas` | Imprime todas las rutas y prioridades programadas en `extensions.conf`. |
| **Recargar Dialplan (en caliente)** | `dialplan reload` | Aplica cambios de `extensions.conf` sin reiniciar la PBX. |
| **Recargar Canales SIP (en caliente)** | `pjsip reload` | Aplica cambios de `pjsip.conf` sin reiniciar la PBX. |

---

### Comandos Rápidos DESDE la Terminal de Linux (Bash)
Si necesitas ejecutar comandos sin ingresar interactivamente a la CLI de Asterisk:

```bash
# Recargar configuraciones
sudo docker exec -it novalink asterisk -rx "dialplan reload"
sudo docker exec -it novalink asterisk -rx "pjsip reload"

# Verificar endpoints
sudo docker exec -it novalink asterisk -rx "pjsip show endpoints"

# Ver canales en curso
sudo docker exec -it novalink asterisk -rx "core show channels"
```

---

## 📱 Configuración del Softphone (Linphone)

Para registrar las extensiones de forma segura en Linphone:

1. **Datos de la Cuenta SIP:**
   - **Usuario (SIP Identity):** `101` (o `102` en Sede 1 / `201`, `202` en Sede 2)
   - **Dominio / Servidor Proxy:** `<TU_IP_ZEROTIER>:5061;transport=tls` *(Ejemplo: `10.59.225.35:5061;transport=tls`)*
   - **Contraseña:** `secreto101` (o la correspondiente a la extensión)

2. **Ajustes de Seguridad y Red en Linphone:**
   - **Transporte preferido:** `TLS`.
   - **Cifrado de medios (Media Encryption):** Seleccionar `SRTP`.
   - **Aceptación de Certificados Autofirmados:** En el archivo `~/.config/linphone/linphonerc` (o en las Preferencias avanzadas):
     ```ini
     [sip]
     verify_server_certs=0
     verify_server_cn=0
     ```

---

## 📞 Plan de Numeración y Servicios PBX

| Destino / Código | Función | Lógica de Procesamiento |
| :--- | :--- | :--- |
| **`101`, `102`** | Extensiones Locales Sede 1 | Regla `_10X` en `extensions.conf`. Dial directo a canal PJSIP con flags `tT`. |
| **`201`, `202`** | Extensiones Locales Sede 2 | Regla `_20X` en Sede 2. Acceso remoto desde Sede 1 vía `_2XX` a través de la troncal. |
| **`811`** | **Prueba de Audio (Echo Test)** | Ejecuta `Echo()`. Hace loopback del audio RTP para diagnosticar latencia y códecs. |
| **`812`** | **Sala de Conferencias** | Ejecuta `ConfBridge(812)`. Permite que múltiples usuarios de ambas sedes hablen a la vez. |
| **`_9XXXXXXX!`** | **Simulación Salida PSTN** | Prefijo de escape `9`. Simula llamadas externas hacia la red pública. |
| **Transferencia** | Transferencia atendida / ciega | Activada mediante banderas `t` (destino) y `T` (llamante) en `Dial()`. |
| **Desconexión Hold** | Corte automático a los 15 min | Parámetro `rtp_timeout_hold=900` en `pjsip.conf` corta la llamada zombie tras 900s de inactividad RTP. |

---

## 🌐 Interconexión Rápida con Otros Equipos (Sedes Externas)

Si durante la defensa el profesor solicita interconectar la central con otro grupo (ej. Sede 3, extensiones `3XX`, IP `10.59.X.Y`):

### 1. En `pjsip.conf` (Definición de la Troncal)

Añade el siguiente bloque al final del archivo, reemplazando `[IP_SEDE_3]` por la dirección IP de la PBX remota en ZeroTier:

```ini
; =========================================
; TRONCAL HACIA NUEVO EQUIPO (SEDE 3)
; =========================================
[trunk-sede3]
type=endpoint
transport=transport-tls
context=sedes_internas
disallow=all
allow=g722
allow=ulaw
allow=alaw
media_encryption=sdes
aors=trunk-sede3

[trunk-sede3]
type=aor
contact=sip:[IP_SEDE_3]:5061

[trunk-sede3]
type=identify
endpoint=trunk-sede3
match=[IP_SEDE_3]
```
*(Nota: Si el otro equipo no tiene TLS configurado y usa UDP estándar, cambia a `transport=transport-udp`, puerto `5060` y omite `media_encryption=sdes`).*

### 2. En `extensions.conf` (Reglas de Enrutamiento)

Añade la regla de marcado para desviar el tráfico hacia la nueva sede (ejemplo para un plan de numeración de extensiones `_3XX`):

```ini
; =========================================
; ENRUTAMIENTO HACIA SEDE 3
; =========================================
exten => _3XX,1,NoOp(--- Enrutando llamada hacia Sede 3 ---)
exten => _3XX,n,Dial(PJSIP/${EXTEN}@trunk-sede3,30,tT)
exten => _3XX,n,Hangup()
```

### 3. Ejecutar en bash (Recargar Asterisk)

Para que los cambios surtan efecto sin reiniciar el contenedor, ejecuta:

```bash
sudo docker exec -it novalink asterisk -rx "pjsip reload"
sudo docker exec -it novalink asterisk -rx "dialplan reload"
```

---

## 🔧 Resolución de Problemas Frecuentes (Troubleshooting)

1. **Error: `Transport 'transport-udp' could not be started: Address already in use`**
   - **Causa:** Asterisk ya tiene el puerto ocupado e intenta reabrirlo con `pjsip reload`.
   - **Solución:** Como operamos en TLS 5061, nos aseguramos de que no existan conflictos de puertos y simplemente reiniciamos el contenedor si ocurre:
     ```bash
     sudo docker restart novalink
     ```

2. **Inyectar configuraciones modificadas sin reiniciar el contenedor:**
   Si no se usaron volúmenes `-v` y necesitas actualizar los archivos dentro del contenedor:
   ```bash
   sudo docker exec -i novalink sh -c 'cat > /etc/asterisk/pjsip.conf' < config/pjsip.conf
   sudo docker exec -i novalink sh -c 'cat > /etc/asterisk/extensions.conf' < config/extensions.conf
   sudo docker exec -it novalink asterisk -rx "pjsip reload"
   sudo docker exec -it novalink asterisk -rx "dialplan reload"
   ```

3. **Audio Unidireccional o Sin Audio:**
   - Comprueba que el contenedor fue iniciado con `--network host`.
   - Confirma que ambas máquinas tienen conexión mutua en ZeroTier (`ping 10.59.X.Y`).
   - Verifica en Linphone que el códec de audio esté configurado en `PCMU` (ulaw) o `PCMA` (alaw).

4. **Verificar Logs de Desconexión / Auditoría:**
   Para inspeccionar los registros generados en disco:
   ```bash
   sudo docker exec -it novalink tail -n 50 /var/log/asterisk/messages
   ```
