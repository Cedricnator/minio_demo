# MinIO Demo - Frontend + Backend + Storage

Proyecto de demostración para subir imágenes a MinIO con Angular y Spring Boot.

## Flujo de Subida de Archivos

### Frontend (Angular)
1. Usuario selecciona archivo mediante drag & drop o click
2. El componente valida tamaño (máx 10MB) y genera preview si es imagen
3. Al hacer click en "Subir Archivo", el `FileUploadService` crea un `FormData` con el archivo
4. Envía POST a `/api/v1/files` con el archivo en formato `multipart/form-data`
5. Recibe respuesta JSON con `{ success, message, fileName }`
6. Muestra mensaje de éxito o error

### Backend (Spring Boot)
1. `FileController` recibe la petición POST en `/api/v1/files`
2. Extrae el `MultipartFile` del request
3. `StorageService` valida y procesa el archivo
4. Crea el bucket en MinIO si no existe (mediante `@PostConstruct`)
5. Sube el archivo usando `MinioClient.putObject()` con el nombre original
6. Retorna `FileUploadResponse` con resultado de la operación

### MinIO
1. Recibe el objeto del backend a través del SDK oficial
2. Almacena el archivo en el bucket `demo-bucket`
3. El archivo queda disponible en MinIO con su nombre original
4. Accesible desde consola web: http://localhost:9001

## Requisitos
- Docker y Docker Compose
- Node.js 20+ (para desarrollo)
- Java 21+ (para desarrollo)
- Maven 3.9+ (para desarrollo)
- Angular CLI 20.0.5

## Ejecucion Rapida con Script en ZSH (Linux/MacOS)
1. Dar permisos de ejecucion al script(desde la raiz del repositorio)
```bash
chmod +x script.zh
```
2. Ejecutar el script(desde la raiz del repositorio)
```bash
./script.sh
```

## Ejecución Rápida con Docker
Desde el directorio `minio-ui`:

```bash
docker compose up --build -d
```

Desde el directorio `minio-api`:
```bash
docker compose up --build -d
```

## Desarrollo Local
### Backend (Spring Boot)

```bash
cd minio-api

# Iniciar MinIO
docker compose up -d

# Ejecutar backend
mvn spring-boot:run
```
Backend en: 
```bash
http://localhost:8080
```

### Frontend (Angular)
```bash
cd minio-ui

# Instalar dependencias
npm install

# Ejecutar en desarrollo
ng serve -o
```

Frontend en: 
```
http://localhost:4200
```

## Estructura del Proyecto

```bash
minio-demo/
├── minio-api/                    # Backend Spring Boot
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       │   └── cl/ufro/dci/minio/
│   │       │       ├── config/      # Configuración MinIO y CORS
│   │       │       ├── controllers/ # REST Controllers
│   │       │       └── services/    # Lógica de negocio
│   │       └── resources/
│   │           └── application.yaml # Configuración Spring
│   ├── Dockerfile
│   ├── docker-compose.yaml
│   └── pom.xml
│
└── minio-ui/                 # Frontend Angular
    ├── src/
    │   ├── app/
    │   │   ├── minio/       # Componente de upload
    │   │   └── services/    # Servicio HTTP
    │   └── environments/    # Configuración de entornos
    ├── Dockerfile
    ├── docker-compose.yaml
    ├── nginx.conf
    └── package.json
```

## Endpoints API
### Upload de Archivos
- **POST** `/api/files/upload`
- **Content-Type**: `multipart/form-data`
- **Parámetro**: `file` (archivo de imagen)

Ejemplo con cURL:
```bash
curl -X POST http://localhost:8080/api/files/upload \
  -F "file=@imagen.jpg"
```

## Servicios Docker
### MinIO
- Puerto API: 9100
- Puerto Console: 9101
- Usuario: minioadmin
- Contraseña: minioadmin
- Bucket: demo-bucket (se crea automáticamente)

### Backend
- Puerto: 8089
- Java 21 + Spring Boot 3.5.7
- Health check: `/actuator/health`

### Frontend
- Puerto: 80
- Nginx + Angular
- Proxy API → Backend

## Variables de Entorno (Backend)

En `application.yaml`:

```yaml
server:
  port: 8080

minio:
  url: http://localhost:9100        # URL de MinIO
  access:
    key: minioadmin                 # Access key
  secret:
    key: minioadmin                 # Secret key
  bucket:
    name: demo-bucket               # Nombre del bucket
  secure: false                     # HTTPS habilitado
```

En Docker se configuran automáticamente vía `docker-compose.yaml`.

## Configuración de Entornos (Frontend)
### Development
```typescript
// environment.development.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api'
};
```

### Production
```typescript
// environment.ts
export const environment = {
  production: true,
  apiUrl: '/api'  // Proxy via Nginx
};
```

## Comandos Útiles

### Docker
```bash
# Construir e iniciar todos los servicios
docker compose up --build

# Iniciar en segundo plano
docker compose up -d

# Ver logs
docker compose logs -f

# Detener servicios
docker compose down

# Limpiar todo (incluyendo volúmenes)
docker compose down -v
```

### Maven

```bash
# Compilar
mvn clean package

# Ejecutar tests
mvn test

# Ejecutar aplicación
mvn spring-boot:run
```

### NPM/Angular
```bash
# Instalar dependencias
npm install

# Desarrollo
npm start

# Build producción
npm run build

# Tests
npm test
```

## Flujo del Backend
1. Descargar proyecto desde Spring Initializer
Utilizar dependencias como `Spring Web`
```bash
https://start.spring.io
```
2. Descomprimir y abrir proyecto
```bash
unzip nombre_proyecto
``` 

3. Agregar Dependencias Necesarias en POM
```xml
<dependency>
  <groupId>io.minio</groupId>
  <artifactId>minio</artifactId>
  <version>8.5.7</version>
</dependency>

<dependency>
  <groupId>org.projectlombok</groupId>
  <artifactId>lombok</artifactId>
  <optional>true</optional>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

4. Crear docker-compose.yml
```yaml
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    hostname: minio
    ports:
      - "9100:9000"
      - "9101:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio-data:/data
    networks:
      - minio_demo_network
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 30s
      timeout: 20s
      retries: 3
      start_period: 10s
volumes:
  minio-data:
    driver: local

networks:
  minio_demo_network:
    external: true
```

5. Agregar Variables de Entorno en application.yaml
```yaml
# application.yaml
spring:
  application:
    name: minio
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health
  endpoint:
    health:
      show-details: always
  
minio:
  url: http://localhost:9100
  access:
    key: minioadmin
  secret:
    key: minioadmin
  bucket:
    name: demo-bucket
  secure: false
```

6. Agregar Configuracion de Minio
```java
// MinioConfig.java
package cl.ufro.dci.minio.config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.minio.MinioClient;

@Configuration
public class MinioConfig {
  @Value("${minio.url}")
  private String url;

  @Value("${minio.access.key}")
  private String accessKey;

  @Value("${minio.secret.key}")
  private String secretKey;

  @Bean()
  public MinioClient minioClient() {
    return MinioClient.builder()
        .endpoint(url)
        .credentials(accessKey, secretKey)
        .build();
  }
}
```

7. Crear Servicio para manipular Minio
```java
// StorageService.java
package cl.ufro.dci.minio.services;

import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.errors.MinioException;
import jakarta.annotation.PostConstruct;
import lombok.extern.log4j.Log4j2;

@Service() 
@Log4j2
public class StorageService {
  @Autowired()
  private MinioClient minioClient;

  @Value("${minio.bucket.name}")
  private String bucketName;

  @PostConstruct
  public void init() {
    try {
      boolean exists = minioClient.bucketExists(
          BucketExistsArgs.builder().bucket(bucketName).build()
      );
      if (!exists) {
        minioClient.makeBucket(
            MakeBucketArgs.builder().bucket(bucketName).build()
        );
        log.info("Bucket '{}' created successfully", bucketName);
      } else {
        log.info("Bucket '{}' already exists", bucketName);
      }
    } catch (MinioException | IOException | InvalidKeyException | NoSuchAlgorithmException e) {
      log.error("Error initializing bucket", e);
      throw new RuntimeException("Failed to initialize MinIO bucket", e);
    }
  }

  public void uploadFile(MultipartFile file){
    try (InputStream inputStream = file.getInputStream()) {
      minioClient.putObject(
          PutObjectArgs.builder()
            .bucket(bucketName)
            .object(file.getOriginalFilename())
            .stream(inputStream, file.getSize(), -1)
            .contentType(file.getContentType())
            .build()
      );
    } catch (MinioException | IOException | InvalidKeyException | NoSuchAlgorithmException e) {
      log.error("Error uploading file to MinIO", e);
      throw new RuntimeException("Error subiendo archivo a MinIO", e);    
    }
  }
}
```

8. Crear DTO de respuesta
```java
// FileUploadResponse.java
package cl.ufro.dci.minio.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FileUploadResponse {
  private boolean success;
  private String message;
  private String fileName;
}
```

9. Crear controlador
```java
// FileController.java
package cl.ufro.dci.minio.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import cl.ufro.dci.minio.dto.FileUploadResponse;
import cl.ufro.dci.minio.services.StorageService;
import lombok.extern.log4j.Log4j2;

@RestController
@RequestMapping("/api/v1/files")
@Log4j2
public class FileController {
  @Autowired
  private StorageService storageService;

  @PostMapping(consumes=org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
  public ResponseEntity<FileUploadResponse> postMethodName(@RequestParam("file") MultipartFile file) {
    log.info("Subiendo un nuevo archivo...");
    try {
      storageService.uploadFile(file); 
      FileUploadResponse response = new FileUploadResponse(
        true,
        "Archivo subido exitosamente",
        file.getOriginalFilename()
      );
      log.info("Archivo subido: {}", file.getOriginalFilename());
      return ResponseEntity.status(HttpStatus.OK).body(response);
    } catch (Exception e) {
      log.error("Error uploading file", e);
      FileUploadResponse response = new FileUploadResponse(
        false,
        "Ocurrió un problema al subir el archivo: " + e.getMessage(),
        file.getOriginalFilename()
      );
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
  }
}
```

10. Probar servicios
- Levantar MinIO 
```bash
docker compose up -d
```
- Levantar SpringBoot
```bash
mvn spring-boot:run
```
- Probar con CURL
```bash
curl -X POST http://localhost:8080/api/files \
  -F "file=@imagen.jpg"
```
