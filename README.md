# EaseAssistant

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge)

Aplicación móvil multiplataforma desarrollada con **Flutter** que conecta clientes con profesionales de diversos servicios. Facilita la búsqueda, contratación, gestión de reservas y pagos, ofreciendo una experiencia fluida y segura tanto para usuarios finales como para administradores.

---

## Características

- **UI responsiva y adaptable** — experiencia visual coherente en móvil, tablet y escritorio
- **Navegación declarativa y fluida** — transiciones suaves entre autenticación, panel de usuario, búsqueda y administración
- **Autenticación completa** — registro, inicio de sesión y verificación de identidad (KYC) con almacenamiento seguro de tokens JWT
- **Consumo de API REST** — comunicación con el backend a través de servicios HTTP dedicados por módulo (usuarios, trabajos, reservas, pagos, etc.)
- **Almacenamiento local seguro** — persistencia de tokens y configuración sensible con `flutter_secure_storage`
- **Gestión de estado local** — enfoque sencillo con `StatefulWidget` + `setState`, fácil de mantener para el alcance actual del proyecto

---

## Stack tecnológico

| Categoría          | Tecnología / Biblioteca                            |
|--------------------|----------------------------------------------------|
| Framework          | Flutter (SDK ≥ 3.10)                               |
| Lenguaje           | Dart (≥ 3.0)                                       |
| UI y estilos       | `google_fonts` (Poppins), `flutter_svg`            |
| Red                | `http`                                             |
| Almacenamiento     | `flutter_secure_storage`                           |
| Autenticación      | `jwt_decoder`                                      |
| Utilidades         | `url_launcher`, `file_picker`, `flutter_slidable`  |
| Gestión de estado  | `StatefulWidget` + `setState`                      |

---

## Instalación

```bash
# 1. Clona el repositorio
git clone https://github.com/Gomrodjes/EaseAssistant-Frontend.git
cd EaseAssistant-Frontend

# 2. Instala las dependencias
flutter pub get

# 3. Ejecuta la aplicación (con dispositivo o emulador conectado)
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

La URL base se inyecta en tiempo de compilación mediante `--dart-define`, sin necesidad de un archivo `.env`. El archivo `lib/config/app_config.dart` expone dos variables:

| Variable             | Valor por defecto          | Descripción                                                                 |
|----------------------|----------------------------|-----------------------------------------------------------------------------|
| `API_BASE_URL_LOCAL` | `http://localhost:8082`    | En emuladores Android, `localhost` se reemplaza automáticamente por `10.0.2.2` |
| `API_BASE_URL_HOST`  | —                          | URL de producción; tiene prioridad sobre la local si se define              |

```bash
# Ejemplo: compilar apuntando a producción
flutter run --dart-define=API_BASE_URL_HOST=https://api.easeassistant.com
```

---

## Estructura del proyecto

```
lib/
├── config/          # Configuración global (colores, medidas, endpoints)
├── core/            # Utilidades centrales (almacenamiento seguro)
├── models/          # Modelos de datos
│   ├── api/         # Modelos para respuestas de API
│   └── core/        # Modelos de dominio compartidos
├── services/        # Capa de acceso a datos y comunicación con la API
├── views/           # Pantallas organizadas por módulo
│   ├── admin/       # Panel de administración y gestión de usuarios
│   ├── auth/        # Autenticación (login, registro, verificación)
│   └── user/        # Vistas del usuario final (servicios, reservas, pagos)
├── main.dart        # Punto de entrada, configuración y splash screen
└── assets/
    └── images/      # Recursos gráficos e iconos SVG
```

---

## Build de producción

```bash
# APK universal
flutter build apk

# Android App Bundle (recomendado para Google Play)
flutter build appbundle
```

---

## Plataformas soportadas

Android · iOS · Web · Linux · macOS · Windows

---

## Futuras mejoras

- Migrar la gestión de estado a **Riverpod** o **Bloc** para mayor escalabilidad
- Implementar tests unitarios y de widgets
- Añadir CI/CD con **GitHub Actions**
- Soporte para modo oscuro y personalización de temas
- Integración con **Firebase** para notificaciones push y analíticas
- Mejoras de accesibilidad y soporte multiidioma

---

## Autor

**Jesús A. Gómez Rodríguez** · [@Gomrodjes](https://github.com/Gomrodjes)

Repositorio: [EaseAssistant-Frontend](https://github.com/Gomrodjes/EaseAssistant-Frontend)

---

## Licencia

Distribuido bajo la licencia [MIT](LICENSE).
