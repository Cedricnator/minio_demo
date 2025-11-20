import { Component, ChangeDetectorRef, signal, ChangeDetectionStrategy } from "@angular/core";
import { CommonModule } from '@angular/common';
import { FileUploadService } from '../services/file-upload.service';

@Component({
  selector: "app-minio",
  standalone: true,
  imports: [CommonModule],
  templateUrl: "./minio.component.html",
  styleUrls: ["./minio.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MinioComponent {
  public selectedFile = signal<File | null>(null);
  public imagePreview = signal<string | null>(null);
  public isDragging = signal<boolean>(false);
  public uploadSuccess = signal<boolean>(false);
  public errorMessage = signal<string>('');

  constructor(
    private fileUploadService: FileUploadService,
    private cdr: ChangeDetectorRef
  ) {}

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging.set(true);
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging.set(false);
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging.set(false);

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.handleFile(files[0]);
    }
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.handleFile(input.files[0]);
    }
  }

  handleFile(file: File): void {
    if (file.size > 10 * 1024 * 1024) {
      this.errorMessage.set('El archivo es muy grande. Máximo 10MB');
      return;
    }

    this.selectedFile.set(file);
    this.errorMessage.set('');
    this.uploadSuccess.set(false);

    // Generate preview only for images
    if (file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onload = (e: ProgressEvent<FileReader>) => {
        this.imagePreview.set(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    } else {
      this.imagePreview.set(null);
    }
  }

  removeFile(event: Event): void {
    event.stopPropagation();
    this.selectedFile.set(null);
    this.imagePreview.set(null);
    this.errorMessage.set('');
  }

  uploadFile(): void {
    if (!this.selectedFile()) return;

    this.errorMessage.set('');

    this.fileUploadService.uploadFile(this.selectedFile()!).subscribe({
      next: (response) => {
        this.uploadSuccess.set(true);
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Error uploading file:', error);
        this.errorMessage = error.error?.message || 'Error al subir el archivo. Por favor intenta de nuevo.';
        this.cdr.detectChanges();
      }
    });
  }

  resetUpload(): void {
    this.selectedFile.set(null)
    this.imagePreview.set(null)
    this.uploadSuccess.set(false)
    this.errorMessage.set('');
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }
}
