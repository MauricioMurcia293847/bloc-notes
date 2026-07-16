# Release Android

Esta guia documenta la Fase 7: pruebas, firma y builds Android.

## Validacion previa

```powershell
flutter analyze
flutter test
```

Estado actual:

- `flutter analyze`: sin issues.
- `flutter test`: pruebas actuales pasando.
- APK release instalado y abierto correctamente en emulador Pixel 7.

## Firma local

La firma release usa `android/key.properties`, archivo que no se sube a Git.
Debe apuntar a una keystore local protegida.

Ejemplo:

```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Guarda la keystore y los passwords con mucho cuidado. Si se pierde la llave,
publicar actualizaciones en Play Store se vuelve mucho mas complicado.

## Build de prueba

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Salida esperada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build actual generado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Build para Play Store

```powershell
flutter build appbundle --release `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Salida esperada:

```text
build/app/outputs/bundle/release/app-release.aab
```

Build actual generado:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Evidencia

La captura de verificacion del APK release instalado se encuentra en:

```text
docs/screenshots/release-check.png
```

## Distribucion antes de Play Store

Mientras la cuenta de Play Console no este lista, se puede compartir el APK por:

- GitHub Releases para pruebas manuales.
- Firebase App Distribution para testers privados.

Play Store sigue siendo la ruta recomendada para produccion.
