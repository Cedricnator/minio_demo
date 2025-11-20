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
