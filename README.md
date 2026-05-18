# EaseAssistant

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge)

Aplicación multiplataforma desarrollada con **Flutter** para conectar clientes con asistentes de distintos servicios. La app permite registrarse, verificar la cuenta, solicitar servicios, gestionar reservas y administrar el sistema desde un panel interno.

---

## Características

- **UI responsiva y adaptable** para móvil, tablet y escritorio.
- **Autenticación completa** con registro, inicio de sesión y verificación por correo.
- **Flujo por roles** para cliente, asistente y administrador.
- **Consumo de API REST** mediante servicios HTTP desacoplados por módulo.
- **Almacenamiento seguro local** con `flutter_secure_storage` para tokens JWT.
- **Gestión documental** para el proceso de validación de asistentes.
- **Gestión de reservas** con seguimiento de servicios contratados.

---

## Stack tecnológico

| Categoría         | Tecnología / Biblioteca                           |
|-------------------|---------------------------------------------------|
| Framework         | Flutter (SDK >= 3.10)                             |
| Lenguaje          | Dart (>= 3.0)                                     |
| UI y estilos      | `google_fonts`, `flutter_svg`                     |
| Red               | `http`                                            |
| Almacenamiento    | `flutter_secure_storage`                          |
| Autenticación     | `jwt_decoder`                                     |
| Utilidades        | `url_launcher`, `file_picker`, `flutter_slidable` |
| Gestión de estado | `StatefulWidget` + `setState`                     |

---

## Instalación

```bash
# 1. Clona el repositorio
git clone https://github.com/Gomrodjes/EaseAssistant-Frontend.git
cd EaseAssistant-Frontend

# 2. Instala las dependencias
flutter pub get

# 3. Ejecuta la aplicación
flutter run
```

### Dependencias (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.2.1
  google_fonts: ^8.1.0
  http: ^1.5.0
  flutter_secure_storage: ^10.0.0
  jwt_decoder: ^2.0.1
  url_launcher: ^6.3.1
  flutter_slidable: ^3.1.2
  file_picker: ^10.3.2
```

---

## Configuración de la API

La URL base se inyecta en tiempo de compilación mediante `--dart-define`, sin necesidad de archivo `.env`.

| Variable             | Valor por defecto       | Descripción                                                                     |
|----------------------|-------------------------|---------------------------------------------------------------------------------|
| `API_BASE_URL_LOCAL` | `http://localhost:8082` | En emuladores Android, `localhost` se reemplaza automáticamente por `10.0.2.2` |
| `API_BASE_URL_HOST`  | -                       | URL de producción; tiene prioridad sobre la local si se define                  |

```bash
flutter run --dart-define=API_BASE_URL_HOST=https://api.easeassistant.com
```

---

## Manual de usuario

Esta sección resume cómo se utiliza la aplicación desde el punto de vista del usuario final.

### 1. Acceso a la aplicación

1. Al abrir la app se muestra una pantalla de bienvenida.
2. Después del splash, el usuario accede a la pantalla de inicio de sesión.
3. Desde ahí puede:
   - iniciar sesión si ya tiene cuenta,
   - registrarse si es un usuario nuevo.

### 2. Registro y verificación de cuenta

1. El usuario completa el formulario de registro con sus datos personales.
2. Tras crear la cuenta, debe elegir el tipo de uso:
   - **Contratar ayuda** para actuar como cliente.
   - **Trabajar como ayudante** para iniciar el proceso como asistente.
3. La aplicación envía un correo de verificación.
4. Hasta verificar el email no se podrá continuar con normalidad en el sistema.

### 3. Flujo de cliente

El cliente utiliza la aplicación para contratar servicios y revisar sus reservas.

#### Inicio

1. Inicia sesión con una cuenta verificada.
2. En la pantalla principal verá:
   - su acceso al perfil,
   - el listado de servicios contratados,
   - el botón **Contratar ayuda**.

#### Contratación de un servicio

1. Pulsa **Contratar ayuda**.
2. Selecciona el asistente o servicio disponible que mejor se ajuste a su necesidad.
3. Completa la confirmación del servicio indicando:
   - dirección,
   - horario,
   - especificaciones o detalles adicionales.
4. Revisa el resumen final de la reserva.
5. Confirma la contratación para dejar registrada la reserva.

#### Gestión del perfil

Desde el perfil el cliente puede:

- consultar su información personal,
- cerrar sesión,
- eliminar su cuenta de forma permanente.

### 4. Flujo de asistente

El asistente pasa por un proceso de solicitud y validación antes de operar dentro de la plataforma.

#### Solicitud para ser asistente

1. Tras el registro, el usuario elige **Trabajar como ayudante**.
2. Se abre la pantalla para comenzar la aplicación como asistente.
3. Debe completar el proceso de validación de identidad.

#### Documentación requerida

Durante la solicitud se deben subir documentos como:

- documento de identidad,
- certificado de antecedentes penales,
- documento de la Seguridad Social,
- certificados de formación.

Después de enviar la documentación:

1. la solicitud queda registrada,
2. el usuario selecciona sus categorías o áreas de servicio,
3. la cuenta queda pendiente de revisión administrativa.

#### Uso una vez verificado

Cuando la solicitud es aprobada, el asistente puede:

- entrar a su pantalla principal,
- consultar reservas asignadas,
- filtrar la vista por categorías disponibles,
- acceder a su perfil.

### 5. Flujo de administrador

El administrador cuenta con un panel interno para gestionar la plataforma.

Desde el panel de administración puede:

- acceder a **Gestión de usuarios**,
- revisar solicitudes en **Revisión de cuentas**,
- crear nuevos servicios,
- crear nuevas categorías,
- consultar una gráfica resumen de usuarios por género.

#### Revisión de cuentas

En esta sección el administrador puede:

1. abrir una solicitud de asistente,
2. revisar la documentación enviada,
3. aprobar o denegar la cuenta según la validación realizada.

#### Gestión de usuarios

El administrador también puede:

- consultar usuarios registrados,
- revisar su estado,
- actualizar información operativa,
- eliminar usuarios cuando sea necesario.

### 6. Recomendaciones de uso

- Verificar siempre el correo antes de intentar acceder al flujo completo.
- Revisar que los documentos subidos estén en formatos válidos: `jpg`, `jpeg`, `png` o `pdf`.
- Usar la opción de refresco en pantallas principales si la información no aparece actualizada.
- Confirmar bien la dirección y el horario antes de cerrar una reserva.

### 7. Usuarios de prueba creados

La siguiente tabla puede usarse para dejar documentados los usuarios de prueba o demostración disponibles en el sistema.

| Nombre | Correo | Rol | Estado | Contraseña | Observaciones |
|--------|--------|-----|--------|------------|---------------|
| Admin | admin@gmail.com | ADMIN | Activo | 123456 | Completar con los datos reales |
| Asistente | asistente@gmail.com | ASISTENTE | Activo | 123456 | Completar con los datos reales |
| Cliente | cliente@gmail.com | CLIENTE | Activo | 123456 | Completar con los datos reales |

---

## Estructura del proyecto

```text
lib/
|-- config/          # Configuración global (colores, medidas, endpoints)
|-- core/            # Utilidades centrales (almacenamiento seguro)
|-- models/          # Modelos de datos
|   |-- api/         # Modelos para respuestas de API
|   `-- core/        # Modelos de dominio compartidos
|-- services/        # Capa de acceso a datos y comunicación con la API
|-- views/           # Pantallas organizadas por módulo
|   |-- admin/       # Panel de administración y gestión de usuarios
|   |-- auth/        # Autenticación (login, registro, verificación)
|   `-- user/        # Vistas de cliente, asistente y perfil
|-- main.dart        # Punto de entrada y splash screen
`-- assets/
    `-- images/      # Recursos gráficos e iconos SVG
```

---

## Build de producción

```bash
flutter build apk
flutter build appbundle
```

---

## Plataformas soportadas

Android · iOS · Web · Linux · macOS · Windows

---

## Futuras mejoras

- Migrar la gestión de estado a **Riverpod** o **Bloc**.
- Implementar tests unitarios y de widgets.
- Añadir CI/CD con **GitHub Actions**.
- Mejorar accesibilidad y soporte multiidioma.
- Integrar notificaciones push y analítica.

---

## Autor

**Jesús A. Gómez Rodríguez** · [@Gomrodjes](https://github.com/Gomrodjes)

Repositorio: [EaseAssistant-Frontend](https://github.com/Gomrodjes/EaseAssistant-Frontend)

---

## Licencia

Distribuido bajo la licencia [MIT](LICENSE).
