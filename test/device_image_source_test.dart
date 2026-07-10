import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mustalazimat_al_nakhla/utils/device_image_source.dart';

void main() {
  group('DeviceImageSource', () {
    test('returns the correct label for gallery and camera', () {
      expect(DeviceImageSource.gallery.label, 'المعرض');
      expect(DeviceImageSource.camera.label, 'الكاميرا');
    });

    test('maps to the correct ImagePicker source', () {
      expect(DeviceImageSource.gallery.imageSource, ImageSource.gallery);
      expect(DeviceImageSource.camera.imageSource, ImageSource.camera);
    });
  });
}
