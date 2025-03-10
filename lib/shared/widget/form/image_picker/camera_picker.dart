//#TEMPLATE reuseable_camera_picker
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class QCameraPicker extends StatefulWidget {
  final String label;
  final String? value;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final bool obscure;
  final Function(String) onChanged;
  final String? provider;

  const QCameraPicker({
    super.key,
    required this.label,
    this.value,
    this.validator,
    this.hint,
    this.helper,
    required this.onChanged,
    this.obscure = false,
    this.provider = "cloudinary",
  });

  @override
  State<QCameraPicker> createState() => _QCameraPickerState();
}

class _QCameraPickerState extends State<QCameraPicker> {
  String? imageUrl;
  bool loading = false;
  late TextEditingController controller;
  @override
  void initState() {
    imageUrl = widget.value;
    controller = TextEditingController(
      text: widget.value ?? "-",
    );
    super.initState();
  }

  Future<String?> getFileMultiplePlatform() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        "png",
        "jpg",
      ],
      allowMultiple: false,
    );
    if (result == null) return null;
    return result.files.first.path;
  }

  Future<String?> getFileAndroidIosAndWeb() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 40,
    );
    String? filePath = image?.path;
    if (filePath == null) return null;

    final File file = File(filePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String?> uploadFile(String filePath) async {
    if (widget.provider == "cloudinary") {
      return await uploadToCloudinary(filePath);
    }
    return await uploadToImgBB(filePath);
  }

  Future<String> uploadToImgBB(String filePath) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        File(filePath).readAsBytesSync(),
        filename: "upload.jpg",
      ),
    });

    var res = await Dio().post(
      'https://api.imgbb.com/1/upload?key=b55ef3fd02b80ab180f284e479acd7c4',
      data: formData,
    );

    var data = res.data["data"];
    var url = data["url"];
    widget.onChanged(url);
    return url;
  }

  Future<String> uploadToCloudinary(String filePath) async {
    String cloudName = "dotz74j1p";
    String apiKey = "983354314759691";

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        File(filePath).readAsBytesSync(),
        filename: "upload.jpg",
      ),
      'upload_preset': 'yogjjkoh',
      'api_key': apiKey,
    });

    var res = await Dio().post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
    );

    String url = res.data["secure_url"];
    return url;
  }

  browsePhoto() async {
    if (loading) return;

    String? base64Image;
    loading = true;
    setState(() {});

    if (!kIsWeb && Platform.isWindows) {
      base64Image = await getFileMultiplePlatform();
    } else {
      base64Image = await getFileAndroidIosAndWeb();
    }
    if (base64Image == null) return;

    imageUrl = base64Image;
    loading = false;

    if (imageUrl != null) {
      widget.onChanged(imageUrl!);
      controller.text = imageUrl!;
    }
    setState(() {});
  }

  String? get currentValue {
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FormField(
        initialValue: false,
        validator: (value) {
          if (widget.validator != null) {
            return widget.validator!(imageUrl ?? "");
          }
          return null;
        },
        enabled: true,
        builder: (FormFieldState<bool> field) {
          ImageProvider image;
          if (imageUrl != null && imageUrl!.startsWith("http")) {
            image = NetworkImage(
              imageUrl ?? "https://i.ibb.co/S32HNjD/no-image.jpg",
            );
          } else if (imageUrl == null) {
            image = const NetworkImage(
              "https://i.ibb.co/S32HNjD/no-image.jpg",
            );
          } else {
            image = MemoryImage(
              base64Decode(imageUrl!),
            );
          }
          return InkWell(
            onTap: () => browsePhoto(),
            child: Column(
              children: [
                Container(
                  height: 200.0,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xffededed),
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        8.0,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (loading)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      if (loading)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

//#END