# GrocerySaver

Aplicacion movil inteligente para comparar precios de alimentos entre supermercados y comercios locales, ayudando a las familias a ahorrar tiempo y dinero.

## Objetivo

Facilitar decisiones de compra economicas mediante informacion actualizada de precios, promociones y opciones cercanas desde un solo lugar.

## Problema

Los precios de productos basicos cambian entre tiendas y no siempre existe una herramienta practica para comparar rapidamente, planificar compras y controlar el gasto mensual.

## Publico Objetivo

- Hogares que quieren optimizar su presupuesto.
- Jovenes y estudiantes que buscan opciones economicas.
- Personas responsables de las compras semanales.
- Usuarios interesados en promociones y control de gasto.

## Funcionalidades

### Implementadas

- Registro de usuarios con correo y contrasena.
- Inicio de sesion con correo y contrasena.
- Verificacion de correo en modo debug (cuando el backend devuelve `verification_token_debug`).
- Pantallas base de `Login`, `Register` y `Home`.
- Integracion con API REST usando `http`.

### Planificadas

- Comparador de precios entre supermercados y tiendas locales.
- Geolocalizacion para encontrar ofertas cercanas.
- Lista de compras inteligente con calculo de total.
- Alertas de promociones por productos favoritos.
- Historial de compras y seguimiento de gasto mensual.

## Alcance del MVP

- Autenticacion completa y estable con API.
- Flujo basico de usuario: crear cuenta, iniciar sesion, cerrar sesion.
- Base tecnica para integrar modulos de precios, ofertas y listas.

## Arquitectura Actual

- `lib/models`: modelos de datos.
- `lib/services`: consumo de API y configuracion.
- `lib/viewmodels`: logica de presentacion y estado.
- `lib/views`: interfaz de usuario.
- `lib/components`: componentes reutilizables (ej. logo de autenticacion).

## Configuracion de API

La app toma la URL base desde `API_BASE_URL` (`--dart-define`).

Valores recomendados:

- Navegador (web): `http://127.0.0.1:8000/api`
- Emulador Android: `http://10.0.2.2:8000/api`
- Dispositivo fisico (misma red): `http://192.168.1.11:8000/api`

## Como Ejecutar

1. Instalar dependencias:

```bash
flutter pub get
```

2. Ejecutar en navegador:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

3. Ejecutar en emulador Android:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

4. Ejecutar en dispositivo fisico:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.11:8000/api
```

## Requisitos de Backend

- Exponer endpoints bajo `/api/auth/...` (ejemplo: `/api/auth/register/`).
- Responder en formato JSON.
- En desarrollo web, habilitar CORS para el origen de Flutter (`localhost`/`127.0.0.1` con su puerto).
- Si se usa servidor local para dispositivos fisicos, ejecutar backend con:

```bash
python manage.py runserver 0.0.0.0:8000
```

## Roadmap Tecnico

1. Persistencia segura de sesion (`flutter_secure_storage`).
2. Repositorio de precios y cache local.
3. Geolocalizacion y filtrado por distancia.
4. Motor de comparacion y ranking de ofertas.
5. Modulo de lista inteligente y alertas.
6. Analitica de gasto mensual y reportes.
