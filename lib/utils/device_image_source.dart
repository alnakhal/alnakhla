import 'package:image_picker/image_picker.dart';

enum DeviceImageSource { gallery, camera }

extension DeviceImageSourceExtension on DeviceImageSource {
  String get label {
    switch (this) {
      case DeviceImageSource.gallery:
        return 'المعرض';
      case DeviceImageSource.camera:
        return 'الكاميرا';
    }
  }

  ImageSource get imageSource {
    switch (this) {
      case DeviceImageSource.gallery:
        return ImageSource.gallery;
      case DeviceImageSource.camera:
        return ImageSource.camera;
    }
  }
}
