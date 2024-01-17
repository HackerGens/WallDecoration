import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DecorationApp(),
    );
  }
}

class DecorationApp extends StatefulWidget {
  @override
  _DecorationAppState createState() => _DecorationAppState();
}

class _DecorationAppState extends State<DecorationApp> {
  List<String> wallImages = [];
  List<DecorationItem> decorations = [];
  Offset dragEndPosition = Offset(0, 0);
  GlobalKey _galleryKey = GlobalKey();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoration App'),
      ),
      body: wallImages.isEmpty
          ? Center(
        child: ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Add Image'),
        ),
      )
          : Screenshot(
        controller: screenshotController,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              key: _galleryKey,
              itemCount: wallImages.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(wallImages[index])),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.white,
              ),
              pageController: PageController(),
            ),
            Positioned.fill(
              child: Stack(
                children: decorations.map((decoration) {
                  return Positioned(
                    left: decoration.left,
                    top: decoration.top,
                    child: Draggable(
                      onDragEnd: (details) {
                        final RenderBox galleryBox = _galleryKey.currentContext!.findRenderObject() as RenderBox;
                        final galleryPosition = galleryBox.globalToLocal(details.offset);
                        setState(() {
                          decoration.left = galleryPosition.dx;
                          decoration.top = galleryPosition.dy;
                          dragEndPosition = galleryPosition;
                        });
                      },
                      feedback: decoration.widget,
                      childWhenDragging: Container(),
                      child: decoration.widget,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _addDecoration(Icons.access_time),
            child: const Icon(Icons.access_time),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _saveImage,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          wallImages.add(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _addDecoration(IconData icon) {
    setState(() {
      decorations.add(DecorationItem(left: dragEndPosition.dx, top: dragEndPosition.dy, widget: Icon(icon)));
    });
  }

  Future<void> _saveImage() async {
    try {
      final screenshotBytes = await screenshotController.capture();
      final result = await ImageGallerySaver.saveImage(screenshotBytes!);
      print(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot saved to gallery')));
    } catch (e) {
      print("Error saving screenshot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving screenshot')),
      );
    }
  }

}

class DecorationItem {
  double left;
  double top;
  Widget widget;
  DecorationItem({required this.left, required this.top, required this.widget});
}
