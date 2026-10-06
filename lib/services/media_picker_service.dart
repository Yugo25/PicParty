import 'package:image_picker/image_picker.dart';
class MediaPickerService {
  final ImagePicker _picker=ImagePicker();
  Future<XFile?> gallery({bool video=false})=>_picker.pickMedia();
  Future<XFile?> camera({bool video=false})=>video?_picker.pickVideo(source:ImageSource.camera,maxDuration:const Duration(minutes:5)):_picker.pickImage(source:ImageSource.camera,imageQuality:92);
}
