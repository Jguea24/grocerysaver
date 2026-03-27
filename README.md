# GrocerySaver

Aplicacion Flutter para compras inteligentes y gestion del hogar conectada a un backend Django REST Framework.

El proyecto concentra en una sola app:

- autenticacion con JWT
- login tradicional y login con Google
- catalogo de productos y categorias
- comparador de precios
- carrito de compras
- checkout, direcciones y pago
- inventario del hogar
- alertas por caducidad
- escaneo QR / codigo de barras
- perfil de usuario

## 1. Objetivo del proyecto

GrocerySaver busca centralizar tareas comunes de compra y control del hogar:

- comparar precios entre tiendas
- agregar productos al carrito
- administrar inventario domestico
- detectar productos proximos a caducar
- revisar ordenes y envios
- usar escaneo para encontrar productos rapidamente

La app consume endpoints REST reales del backend. No esta planteada como demo con mocks: la mayoria de pantallas principales se alimentan de la API.

## 2. Tecnologias utilizadas

### Flutter y Dart

- `Flutter`
- `Dart`
- `Material 3`

### Manejo de estado

- `provider`

Se usa `Provider` principalmente en la capa nueva `app/data/domain/presentation`, sobre todo para:

- autenticacion
- dashboard
- inventario
- carrito
- detalle de producto
- escaner

### Consumo HTTP y persistencia

- `http`
- `flutter_secure_storage`

`http` se usa para consumir la API REST y `flutter_secure_storage` para guardar tokens JWT y otros datos sensibles.

### UI y experiencia

- `google_fonts`
- `url_launcher`

### Camara y archivos

- `mobile_scanner`
- `image_picker`

### Notificaciones y sensores

- `flutter_local_notifications`
- `sensors_plus`

### Integracion Google

- `google_sign_in`
- `google_sign_in_web`

## 3. Arquitectura usada (MVVM)

El proyecto se esta trabajando bajo **MVVM**, con una transicion gradual desde codigo previo. La organizacion actual se puede leer asi:

### A. Model

Responsable de entidades, contratos y acceso a datos.

- `lib/domain` (entidades y contratos)
- `lib/data` (repositorios concretos y cliente API principal)
- `lib/models` (modelos usados por modulos existentes)
- `lib/services` (servicios HTTP de modulos clasicos)
- `lib/core` (servicios transversales)

### B. ViewModel

Orquesta el estado, la logica de presentacion y las llamadas al Model.

- `lib/presentation/providers` (estado del flujo principal)
- `lib/viewmodels` (estado de vistas modulares)

### C. View

Contiene pantallas, widgets y rutas.

- `lib/presentation/screens` (pantallas principales nuevas)
- `lib/views` (pantallas modulares)
- `lib/components` (widgets reutilizables)
- `lib/app` (rutas y configuracion general)

### Flujo MVVM esperado

1. La **View** dispara acciones del usuario.
2. El **ViewModel** consulta/actualiza el **Model**.
3. El **Model** consume API y devuelve datos.
4. El **ViewModel** emite estado para actualizar la **View**.

### Nota de consolidacion

Hoy la app es hibrida, pero la direccion es **unificar todo en MVVM**. Las carpetas clasicas siguen existiendo mientras se migran pantallas y servicios.

## 4. Estructura de carpetas

```text
lib/
  app/              Configuracion principal de la aplicacion
  components/       Widgets reutilizables del bloque clasico
  core/             Servicios transversales
  data/             Implementaciones concretas y cliente API principal
  domain/           Entidades y contratos
  models/           Modelos usados por servicios/vistas modulares
  presentation/     Providers y pantallas del flujo principal
  services/         Servicios HTTP y configuracion modular
  viewmodels/       Estado para vistas modulares
  views/            Pantallas modulares nuevas
  main.dart         Punto de entrada
```

## 5. Funcionalidades implementadas

### Autenticacion

- login con correo y contrasena
- registro de usuario
- soporte de verificacion de correo si el backend lo exige
- logout
- restauracion de sesion
- login con Google

### Home

- dashboard principal
- categorias
- productos recomendados
- mejores precios / ofertas
- acceso a alertas
- acceso a carrito

### Catalogo y productos

- listado de productos
- vista de detalle
- comparador de precios por tienda
- historial y alternativas segun backend

### Carrito

- agregar productos
- listar items reales desde API
- actualizar cantidad
- eliminar item
- subtotal
- continuidad hacia checkout

### Checkout y pago

- creacion de checkout
- seleccion de direccion
- guardado de direccion en checkout
- seleccion de metodo de pago:
  - tarjeta
  - efectivo
  - transferencia
- pantalla de pago exitoso
- acceso a ordenes y envios

### Inventario del hogar

- listar items reales del inventario
- agregar producto al inventario
- editar cantidad y fecha de caducidad
- eliminar producto
- ver alertas por caducar

### Perfil

- carga del usuario autenticado
- visualizacion de datos del perfil
- cambio de foto de perfil
- consulta de direcciones
- consulta de preferencias
- vista moderna de perfil editable

### Escaner

- lectura QR / codigo de barras con camara
- busqueda manual de codigo
- redireccion al detalle del producto si existe

## 6. Dependencias reales del proyecto

Tomadas desde `pubspec.yaml`:

- `provider: ^6.1.5`
- `http: ^1.2.2`
- `image_picker: ^1.1.2`
- `sensors_plus: ^7.0.0`
- `google_fonts: ^6.2.1`
- `google_sign_in: ^6.2.1`
- `google_sign_in_web: ^0.12.4+4`
- `flutter_secure_storage: ^10.0.0`
- `mobile_scanner: ^5.2.3`
- `flutter_local_notifications: ^19.4.2`
- `url_launcher: ^6.3.1`

## 7. Configuracion de API

La app soporta distintas bases segun plataforma:

- Flutter Web: `http://127.0.0.1:8000/api`
- Android emulator: `http://10.0.2.2:8000/api`

Tambien existe logica para resolver URLs del backend cuando vienen con:

- `localhost`
- `127.0.0.1`
- `10.0.2.2`

Esto se maneja principalmente en:

- `lib/services/api_config.dart`

## 8. Autenticacion y tokens

La autenticacion es por JWT Bearer.

La app envia:

```http
Authorization: Bearer <token>
```

Los tokens se guardan con `flutter_secure_storage`.

En el proyecto hay compatibilidad con claves antiguas y nuevas, por ejemplo:

- `access_token`
- `refresh_token`
- `access`
- `refresh`

Esto se hizo para mantener compatibilidad entre modulos viejos y nuevos.

## 9. Endpoints principales consumidos

### Auth

- `/auth/register/`
- `/auth/login/`
- `/auth/logout/`
- `/auth/me/`
- `/auth/social-login/`
- `/auth/verify-email/`
- `/auth/me/avatar/`

### Catalogo y comparacion

- `/categories/`
- `/products/`
- `/products/<id>/`
- `/compare-prices/`
- `/prices/history/`
- `/offers/`

### Carrito

- `/cart/`
- `/cart/items/`
- `/cart/items/<id>/`

### Checkout, pagos, ordenes y envios

- `/checkout/`
- `/checkout/<id>/`
- `/payments/`
- `/orders/`
- `/orders/<id>/`
- `/shipments/`
- `/shipments/<id>/`

### Inventario y alertas

- `/inventory/items/`
- `/inventory/items/<id>/`
- `/alerts/`

### Perfil

- `/profile/addresses/`
- `/profile/notifications/`
- `/profile/role-change-requests/`

### Otros modulos

- `/products/scan/`
- `/weather/...`
- `/jobs/...`
- `/raffles/active/`

## 10. Flujo principal de la app

### Flujo de compra

1. Catalogo
2. Agregar al carrito
3. Ver carrito
4. Crear checkout
5. Seleccionar direccion
6. Elegir metodo de pago
7. Confirmacion de pago
8. Orden
9. Envio

### Flujo de inventario

1. Agregar producto al inventario
2. Guardar cantidad
3. Guardar fecha de caducidad
4. Backend crea alerta si corresponde
5. La app muestra alertas por caducar

## 11. Pantallas importantes

### Flujo principal

- `lib/presentation/screens/auth/login_screen.dart`
- `lib/presentation/screens/auth/register_screen.dart`
- `lib/presentation/screens/home/app_shell_screen.dart`

### Modulos nuevos

- `lib/views/cart_page.dart`
- `lib/views/checkout_page.dart`
- `lib/views/payment_page.dart`
- `lib/views/payment_success_page.dart`
- `lib/views/orders_page.dart`
- `lib/views/shipment_tracking_page.dart`
- `lib/views/inventory_page.dart`
- `lib/views/profile_view.dart`
- `lib/views/products_page.dart`

## 12. Archivos clave del proyecto

### Configuracion general

- `lib/main.dart`
- `lib/app/grocery_saver_app.dart`
- `lib/app/app_routes.dart`
- `lib/app/app_theme.dart`

### Cliente y repositorio principal

- `lib/data/core/api_client.dart`
- `lib/data/repositories/app_repository_impl.dart`
- `lib/domain/repositories/app_repositories.dart`
- `lib/domain/entities/app_models.dart`

### Providers

- `lib/presentation/providers/app_providers.dart`

### Servicios modulares

- `lib/services/api_client.dart`
- `lib/services/api_config.dart`
- `lib/services/cart_service.dart`
- `lib/services/product_service.dart`
- `lib/services/inventory_service.dart`
- `lib/services/address_service.dart`
- `lib/services/checkout_service.dart`
- `lib/services/payment_service.dart`
- `lib/services/order_service.dart`
- `lib/services/shipment_service.dart`
- `lib/services/profile_api.dart`

## 13. Como ejecutar el proyecto

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar en web

```bash
flutter run -d chrome --web-port 64432 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

### Ejecutar en Android emulator

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### Login con Google en web

Si usas Google Sign-In en web:

```bash
flutter run -d chrome --web-port 64432 --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID.apps.googleusercontent.com
```

## 14. Requisitos del backend

Para que el proyecto funcione correctamente, el backend debe:

- responder JSON
- soportar JWT Bearer
- permitir CORS en desarrollo web
- exponer los endpoints usados por auth, catalogo, carrito, checkout, inventario y perfil
- devolver estructuras coherentes como:
  - `response['products']`
  - `response['items']`
  - `response['alerts']`
  - `response['cart']`
  - `response['checkout']`
  - `response['payment']`
  - `response['order']`
  - `response['shipment']`

## 15. Notas importantes

- El proyecto todavia mezcla codigo nuevo y codigo anterior.
- Algunas pantallas ya estan mas limpias y otras aun pueden consolidarse.
- Hay compatibilidad con varias formas de respuesta del backend porque durante el desarrollo hubo cambios de payload.
- Varias vistas nuevas ya estan listas para produccion a nivel de UI, pero aun conviene seguir unificando la arquitectura.

## 16. Pendientes recomendados

Para dejar el proyecto mas cerrado:

- unificar toda la app en una sola arquitectura
- limpiar codigo viejo que ya no se usa
- completar analisis estatico de todo el repo
- agregar tests de servicios y widgets clave
- cerrar update real del perfil si el backend expone ese endpoint

## 17. Autor y contexto

Este proyecto fue evolucionando sobre una base Flutter existente y fue ampliado para integrarse con un backend Django REST Framework con foco en:

- compras inteligentes
- comparacion de precios
- control de inventario del hogar
- flujo completo de carrito a pago
