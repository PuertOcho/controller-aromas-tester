# PROJECT TRACKER – AromaController (BLE/Wi‑Fi)

> Última actualización: 2025-08-08
>
> Objetivo: App multiplataforma (Android/iOS) para controlar un difusor de aromas comprado en AliExpress, priorizando control local (BLE/LAN), privacidad y confiabilidad. Se realizará ingeniería inversa no intrusiva del protocolo del fabricante para replicar comandos desde nuestra app.

---

## Leyenda de estados
- ✅ Completado
- 🔄 En progreso
- ⏳ Pendiente
- 🚧 Bloqueado

---

## Decisiones Técnicas
- Opción recomendada: React Native (JS/TS)
  - BLE: react-native-ble-plx (control central BLE)
  - Permisos: react-native-permissions
  - LAN/Descubrimiento: react-native-zeroconf (mDNS/Bonjour), react-native-udp o react-native-dgram (UDP), react-native-tcp-socket (TCP)
  - Networking: axios (HTTP), WebSocket nativo
  - Navegación: @react-navigation/native (+ stack/bottom-tabs)
  - Estado: Zustand/Redux (propuesto: Zustand)
  - Almacenamiento: react-native-mmkv
  - Nota Expo: para BLE se requiere Bare o Expo + Dev Client (no funciona en Expo Go)
- Alternativas: Kotlin Multiplatform (Compose Multiplatform), .NET MAUI (C#), Nativo (Kotlin/Swift)
- Herramientas RE/diagnóstico: Wireshark, mitmproxy/Proxyman/Charles, nRF Connect, adb logcat, Frida (solo si es imprescindible para pinning).
- Principios: local-first, mínima superficie de permisos, sin telemetría, datos solo on-device.

---

## Epic 0 – Descubrimiento y RE de Protocolo (BLE y/o LAN)
Descripción: Identificar cómo comunica el dispositivo (BLE GATT, UDP/TCP local, HTTP(s) cloud), mapear comandos (on/off, intensidad, temporizadores) y validar control local.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T0.1 | Preparar entorno de sniffing: Wireshark, mitmproxy, nRF Connect, adb | – | ⏳ |
| T0.2 | Identificar modos de conectividad del difusor (solo BLE / BLE+Wi‑Fi / cloud) | T0.1 | ⏳ |
| T0.3 | Capturar emparejamiento/operación en BLE con nRF Connect y mapear servicios GATT | T0.2 | ⏳ |
| T0.4 | Capturar tráfico LAN (mDNS/SSDP/UDP/TCP). Detectar endpoints locales | T0.2 | ⏳ |
| T0.5 | Documentar comandos: on/off, intensidad, temporizador, modo, batería | T0.3/T0.4 | ⏳ |
| T0.6 | Evaluar TLS/pinning; si hay pinning, priorizar BLE/local antes de bypass | T0.4 | ⏳ |
| T0.7 | Redactar `docs/protocol.md` con frame specs y ejemplos | T0.5 | ⏳ |

Notas: Evitar depender del cloud del fabricante. Si el dispositivo es Tuya/esp‑based, verificar control local/documentación comunitaria.

---

## Epic 1 – Base de App (React Native) y Fundaciones
Descripción: Crear el proyecto RN, permisos, navegación, estado, diseño base y utilidades comunes.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T1.1 | Inicializar proyecto React Native (CLI o Expo + Dev Client) con TypeScript | – | ⏳ |
| T1.2 | Añadir dependencias: ble-plx, permissions, zeroconf, tcp-socket, axios, react-navigation, Zustand, mmkv | T1.1 | ⏳ |
| T1.3 | Configurar permisos Android 12+ (BLUETOOTH_SCAN/CONNECT, ubicación <=11) e iOS (Info.plist BLE) | T1.2 | ⏳ |
| T1.4 | Arquitectura: capas `core`, `data`, `domain`, `ui` y setup de navegación | T1.2 | ⏳ |
| T1.5 | Theming y diseño básico (estilos, tokens) | T1.4 | ⏳ |
| T1.6 | Pipeline CI mínimo (lint, typecheck, tests, build android/ios) | T1.1 | ⏳ |

Detalles permisos:
- Android (AndroidManifest + Gradle): BLUETOOTH, BLUETOOTH_ADMIN (legacy), BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION (≤ Android 11), uses-feature bluetooth-le.
- iOS (Info.plist): NSBluetoothAlwaysUsageDescription, NSBluetoothPeripheralUsageDescription (compat), opcional background mode bluetooth-central si se requiere.

---

## Epic 2 – SDK BLE del Dispositivo
Descripción: Implementar cliente BLE confiable (descubrimiento, conexión, MTU, notificaciones, reintentos) y comandos mapeados.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T2.1 | Escaneo y filtrado por nombres/Manufacturer Data (fingerprint) con ble-plx | T0.3, T1.3 | ⏳ |
| T2.2 | Conexión robusta: timeouts, reintentos, recuperación (ble-plx) | T2.1 | ⏳ |
| T2.3 | Descubrir servicios/características GATT y suscribirse a notificaciones | T2.2 | ⏳ |
| T2.4 | Implementar comandos base (on/off, intensidad, temporizador) | T0.5, T2.3 | ⏳ |
| T2.5 | Validar latencia y estabilidad con dispositivo real | T2.4 | ⏳ |
| T2.6 | Documentar API interna `BleAromaClient` | T2.4 | ⏳ |

Notas: MTU configurable en Android con ble-plx; en iOS lo gestiona el sistema.

---

## Epic 3 – SDK LAN (Wi‑Fi Local) [si aplica]
Descripción: Descubrir el dispositivo en red local y replicar comandos por UDP/TCP/HTTP si el protocolo local existe.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T3.1 | Descubrimiento mDNS/SSDP y escaneo de puertos | T0.4 | ⏳ |
| T3.2 | Handshake local (si procede) y autenticación | T3.1 | ⏳ |
| T3.3 | Implementar transporte (UDP/TCP/HTTP) y framing | T0.5, T3.2 | ⏳ |
| T3.4 | Paridad de comandos con BLE | T3.3 | ⏳ |
| T3.5 | Tolerancia a errores/red y reconexión | T3.3 | ⏳ |

---

## Epic 4 – Capa de Abstracción de Dispositivo
Descripción: Unificar BLE y LAN bajo una interfaz común para la app.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T4.1 | Definir interfaz `AromaDeviceController` (on/off, setIntensity, schedule) | T2.4 | ⏳ |
| T4.2 | Implementación BLE y (opcional) LAN de la interfaz | T4.1, T2.4, T3.4 | ⏳ |
| T4.3 | Estrategia de selección de canal (preferir LAN si disponible) | T4.2 | ⏳ |

---

## Epic 5 – UX de Control y Escenas
Descripción: Flujo de onboarding, emparejamiento/descubrimiento, controles, escenas y programaciones.

| ID | Descripción | Dependencias | Estado |
|----|-------------|--------------|--------|
| T5.1 | Onboarding: permisos, descubrimiento, selección de dispositivo | T1.3, T2.1 | ⏳ |
| T5.2 | Pantalla de control (on/off, intensidad, modo, temporizador) | T4.2 | ⏳ |
| T5.3 | Escenas y perfiles (p. ej. mañana, noche) | T5.2 | ⏳ |
| T5.4 | Programaciones (cron local en app) | T5.2 | ⏳ |
| T5.5 | Estado en tiempo real (suscripciones BLE/LAN) | T4.2 | ⏳ |

---






## Roadmap de Implementación
- Fase 1: Descubrimiento + Fundaciones (Epics 0–1)
- Fase 2: Control BLE (Epics 2, 4, 5 parciales)
- Fase 3: Control LAN opcional (Epic 3) + robustez
- Fase 4: Calidad, seguridad y publicación (Epics 6–8)
- Fase 5: Documentación completa (Epic 9)

Progreso estimado actual: 0% (proyecto inicializado)

---

## Próximos Pasos Inmediatos
1) T0.1 – Instalar y configurar herramientas (Wireshark, mitmproxy, nRF Connect, adb).  
2) T0.2 – Identificar conectividad real del dispositivo (BLE/LAN) y tomar capturas.  
3) T1.1–T1.3 – Inicializar proyecto React Native y configurar permisos BLE.  

---

## Anexo – Herramientas y referencias
- React Native BLE: react-native-ble-plx
- Permisos: react-native-permissions
- LAN/mDNS: react-native-zeroconf, react-native-udp / react-native-dgram, react-native-tcp-socket
- Navegación: React Navigation
- Estado: Zustand/Redux
- Almacenamiento: react-native-mmkv
- Android: adb logcat, permisos BLE/ubicación Android 12+
- iOS: CoreBluetooth, Info.plist y declaraciones de privacidad
