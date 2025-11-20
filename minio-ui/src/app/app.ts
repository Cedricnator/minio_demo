import { Component } from '@angular/core';
import { MinioComponent } from './minio/minio.component';

@Component({
  selector: 'app-root',
  imports: [MinioComponent],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected title = 'minio-ui';
}
