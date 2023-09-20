import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top]
    );

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final allergens = HashSet<String>();
  final allergenStorage = AllergenStorage();
  final noImage = const Icon(
    Icons.image_not_supported,
    size: 150.0,
  );
  final foundAllergens = HashSet<String>();

  late Widget _image = noImage;

  Future<void> _pickAnImage(ImageSource src) async {
    final ImagePicker picker = ImagePicker();

    // Capture a photo.
    final XFile? photo = await picker.pickImage(source: src);

    if (photo == null) {
      return;
    }

    setState(() {
      _image = Image.file(File(photo.path));
      foundAllergens.clear();
    });

    final inputImage = InputImage.fromFilePath(photo.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);

    setState(() {
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          for (var element in line.elements) {
            if (allergens.contains(element.text.toLowerCase())) {
              foundAllergens.add(element.text.toLowerCase());
            }
          }
        }
      }
    });

    textRecognizer.close();
  }

  @override
  void initState() {
    super.initState();
    readAllergens();
  }

  void readAllergens() {
    allergenStorage.readAllergens().then((result) {
      allergens.clear();

      var allergensToAdd = result.split(
          RegExp(r'\s+')
      ).where((s) => s.isNotEmpty).toList();

      for (var allergenToAdd in allergensToAdd) {
        allergens.add(allergenToAdd);
      }
    }); // Todo: Catch Error if the future throws any
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            if (value == 'Set Allergens') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SetAllergensPage(storage: allergenStorage))
              ).then((result) {
                readAllergens();
              }); // Todo: catch errors if there are any thrown by future
            } else if (value == 'About') {
              // Todo: implement
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'Set Allergens',
              child: Text('Set Allergens'),
            ),
            const PopupMenuItem<String>(
              value: 'About',
              child: Text('About'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _image,
              Container(
                height: 30,
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                alignment: Alignment.centerLeft,
                child: const Text('Allergens:'),
              ),
              for (var allergen in foundAllergens)
                Container(
                  height: 30,
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  alignment: Alignment.centerLeft,
                  child: UnorderedListItem(Text(allergen)),
                )
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        height: 56,
        notchMargin: 5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: IconButton(
                  onPressed: () {
                    _pickAnImage(ImageSource.gallery); // Todo: catch future errors
                  },
                  tooltip: 'Open Image Gallery',
                  icon: const Icon(Icons.image)),
            ),
            Container(width: 60),
            Expanded(
              child: IconButton(
                  onPressed: () {},
                  tooltip: 'To do: implement', // Todo: implement
                  icon: const Icon(Icons.close)),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () { _pickAnImage(ImageSource.camera); }, // Todo: catch future errors
        tooltip: 'Open Camera',
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class UnorderedListItem extends StatelessWidget {
  const UnorderedListItem(this.content, {super.key});
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text("• "),
        Expanded(
          child: content,
        ),
      ],
    );
  }
}

class AllergenStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/allergens.txt');
  }

  Future<String> readAllergens() async {
    try {
      final file = await _localFile;
      return await file.readAsString();
    } catch (e) {
      return '';
    }
  }

  Future<File> writeAllergens(String content) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(content);
  }
}

class SetAllergensPage extends StatefulWidget {
  const SetAllergensPage({super.key, required this.storage});

  final AllergenStorage storage;

  @override
  State<SetAllergensPage> createState() => _SetAllergensPageState();
}

class _SetAllergensPageState extends State<SetAllergensPage> with WidgetsBindingObserver {
  var showSavedNotification = () {};
  late StreamSubscription<bool> _keyboardSubscription;

  final _txt = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.storage.readAllergens().then((content) {
      setState(() {
        _txt.text = content;
      });
    });

    var keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        _focusNode.unfocus();
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [SystemUiOverlay.top]
        );
      }
    });

    _focusNode.addListener(() async {
      if (!_focusNode.hasFocus) {
        await widget.storage.writeAllergens(_txt.text);
        showSavedNotification();
      }
    });
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    showSavedNotification = () {
      final snackBar = SnackBar(
        content: const Text('Saved!'),
        action: SnackBarAction(
          label: 'close',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    };

    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set Allergens'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: TextField(
          focusNode: _focusNode,
          controller: _txt,
          keyboardType: TextInputType.multiline,
          maxLines: null,
        ),
      ),
    );
  }
}