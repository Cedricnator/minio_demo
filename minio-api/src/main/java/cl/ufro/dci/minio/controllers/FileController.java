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
