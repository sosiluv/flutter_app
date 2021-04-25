

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/qrscan_screen.dart';
import 'package:flutter_app/screens/webview_screen.dart';
import 'package:flutter_app/screens/qrscan_screen.dart';
import 'package:flutter_app/screens/webview_screen.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:open_file/open_file.dart';
import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';

class StorageMain extends StatefulWidget {
  @override
  _StorageMainState createState() => _StorageMainState();
}

class _StorageMainState extends State<StorageMain> {
  String nowPath = "/";
  List<PlatformFile> _paths;
  List<fs.UploadTask>  _tasks = <fs.UploadTask>[];
  String mkdir = null;
  bool isMkdir = false;
  bool isLoading = false;
  List<ListTile> myList =[];


  openFileExplorer() async{
    isMkdir = false;
    mkdir = null;
    try{
      _paths = (await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true)).files;
    } on PlatformException catch(e){
      print('Unsupported operation' + e.toString());
    } catch(ex){
      print(ex);
    }
    if(!mounted) return;
    print(_paths);
    _paths.forEach((path) async{
      fs.UploadTask task =  await upload(path.name, path.path);
      if(task != null){
        setState(() {
          _tasks =[..._tasks, task];
        });
        task.whenComplete((){
          isMkdir = false;
          mkdir = null;
          _tasks.removeWhere((element) => element.snapshot == task.snapshot);
          myListsHandler(nowPath: nowPath);
        });
      }
    });
  }

  Future<fs.UploadTask> upload(fileName, filePath){
    fs.Reference ref = fs.FirebaseStorage.instance.ref(nowPath).child(fileName);
    fs.UploadTask uploadTask;
    uploadTask = ref.putFile(io.File(filePath));
    return Future.value(uploadTask);
  }

  Future<void> delFromStorage(String path) async{
    await fs.FirebaseStorage.instance.ref(path).delete();
    myListsHandler(nowPath: nowPath);
  }

  Future<List<ListTile>> getMyLists({String path, String mkdirName}) async {
    setState(() {
      isLoading = true;
    });
    io.Directory appDocDir = await getApplicationDocumentsDirectory();
    fs.ListResult result = await fs.FirebaseStorage.instance.ref(path).listAll();
    List<ListTile> temp = [];
    temp.clear();
    print('nowPath : $nowPath');
    temp.add(ListTile(
      title: Text(nowPath),
    ));

    if(nowPath.split('/').length > 2){
      temp.add(ListTile(
        title: Text('...'),
        leading: Icon(Icons.keyboard_backspace),
        onTap: (){
          var nowTemp = nowPath.split('/');
          nowTemp.removeAt(nowTemp.length-2);
          nowPath = nowTemp.join("/");
          isMkdir = false;
          mkdir = null;
          myListsHandler(nowPath: nowPath);
        },
      ));
    }

    result.prefixes.forEach((folder){
      temp.add(ListTile(
        leading: Icon(Icons.folder_rounded),
        title: Text(folder.name),
        onTap: (){
          nowPath = '$nowPath${folder.name}/';
          isMkdir = false;
          mkdir = null;
          myListsHandler(nowPath: nowPath);
        },
      ));
    });

    if(isMkdir){
      temp.add(ListTile(
        leading: Icon(Icons.folder_special_outlined),
        title: Text(mkdir),
        onTap: (){
          print('!!!mkdir!!!');
          nowPath = '$nowPath$mkdir/';
          isMkdir = false;
          mkdir = null;
          myListsHandler(nowPath: nowPath);
        },
      ));
    }


    result.items.forEach((file) {
      io.File downloadToFile = io.File('${appDocDir.path}/fireStorage/$nowPath${file.name}');
      bool isExist = downloadToFile.existsSync();
      temp.add(ListTile(
        title: Text(file.name),
        leading: Stack(
          children: [
            if(isExist) Icon(Icons.check),
            Icon(Icons.file_copy_outlined),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) {
            return [
              PopupMenuItem(value: 'down',child: Text('download'),),
              PopupMenuItem(value: 'del',child: Text('delete'),),
              PopupMenuItem(value: 'open',child: Text('open'),),
            ];
          },
          onSelected: (value) {
            if(value =='del'){
              delFromStorage(nowPath + file.name);
            }
            if(value == 'down'){
              _downloadToAppDir(nowPath + file.name);
            }
            if(value == 'open'){
              openfile(nowPath + file.name);
            }
          },
        ),
      ));
    });
    return temp;
  }
  myListsHandler({@required String nowPath}){
    getMyLists(path: nowPath).then((value){
      setState(() {
        isLoading = false;
        myList = value;
      });
    });
  }

  _downloadToAppDir(String path) async{
    io.Directory appDocDic = await getApplicationDocumentsDirectory();
    io.File downloadToFile = io.File('${appDocDic.path}/fireStorage$path');
    var a = path.split('/')..removeLast();
    io.Directory isDir = io.Directory('${appDocDic.path}/fireStorage${a.join('/')}');
    bool hasExisted = (await isDir.exists());
    if(!hasExisted){
      await isDir.create(recursive: true);
    }
    try{
      var res = await fs.FirebaseStorage.instance.ref(path).writeToFile(downloadToFile);
    } on fs.FirebaseException catch(e){
      print(e);
    }
    myListsHandler(nowPath: nowPath);

  }
  Future<void> openfile(String path) async{
    io.Directory appDocDir =await getApplicationDocumentsDirectory();
    io.File opFilePath = io.File('${appDocDir.path}/fireStorage$path');
    final res = await OpenFile.open(opFilePath.path);
    print(res);
  }

  @override
  void initState() {
    super.initState();
    myListsHandler(nowPath: nowPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isLoading ? Colors.grey: Colors.white,
        appBar: getAppBar(context),
        body: Container(
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: isLoading,
                child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return myList[index];
                    },
                    separatorBuilder: (context, index) {
                      return Divider();
                    },
                    itemCount: myList.length),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  constraints: BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return UploadTaskListTile(task: _tasks[index],onDismissed: ()=>removeTaskAtIndex(index),);
                    },
                  ),
                ),
              )
            ],
          ),
        )
    );
  }
  void removeTaskAtIndex(int index){
    setState(() {
      _tasks = _tasks..removeAt(index);
    });
  }
  Widget getAppBar(BuildContext context){
    final GlobalKey<FormState> _formKey =GlobalKey<FormState>();
    return AppBar(
      title: Text('FireStorage!'),
      actions: [
        IconButton(
          icon: Icon(Icons.note_add_outlined),
          onPressed: (){
            openFileExplorer();
          },
        ),
        IconButton(
          icon: Icon(Icons.create_new_folder),
          onPressed: () async{
            var res = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('임시 디렉토리 명을 입력해 주세요!'),
                  content: Form(
                    key: _formKey,
                    child: TextFormField(
                      onSaved: (newValue) {
                        Navigator.pop(context, newValue);
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: Text('취소')
                    ),
                    TextButton(
                        onPressed: (){
                          _formKey.currentState.save();
                        },
                        child: Text('확인')
                    ),
                  ],
                );
              },
            );
            print('디렉토리 팝업 결과 : $res');
            if(res != null){
              isMkdir = true;
              mkdir = res;
              myListsHandler(nowPath: nowPath);
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.qr_code),
          onPressed: (){
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return QrScanScreen();
                  },
                )
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.wifi_tethering),
          onPressed: (){
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return WebViewScreen();
                },)
            );
          },
        ),
      ],
    );
  }
}


class UploadTaskListTile extends StatelessWidget {
  final fs.UploadTask task;
  final onDismissed;
  const UploadTaskListTile({
    Key key,
    this.task,
    this.onDismissed
  }) : super(key: key);

  String _byteTransferred(fs.TaskSnapshot snapshot){
    return '${snapshot.bytesTransferred}/${snapshot.totalBytes}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: task.snapshotEvents,
      builder: (context,AsyncSnapshot<fs.TaskSnapshot> asnycSnapshot){
        Widget subtitle = const Text('---');
        fs.TaskSnapshot snapshot = asnycSnapshot.data;
        fs.TaskState state = snapshot?.state;
        if(asnycSnapshot.hasError){
          if(asnycSnapshot.error is fs.FirebaseException
              && (asnycSnapshot.error as fs.FirebaseException).code =='canceled'){
            subtitle = const Text('Uplaod candeled.');
          } else {
            print(asnycSnapshot.error);
            subtitle = const Text('Something wnet wrong');
          }
        } else if(snapshot != null){
          subtitle = Text('$state: ${_byteTransferred(snapshot)} byte sent');
        }
        return Dismissible(
            key: Key(task.hashCode.toString()),
            onDismissed: (_) => onDismissed(),
            child: ListTile(
              title: Text('Upload Task #${task.hashCode}'),
              subtitle: subtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(state == fs.TaskState.running)
                    Material(
                      child: IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: task.pause,
                      ),
                    ),
                  if(state == fs.TaskState.running)
                    Material(
                      child: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: task.cancel,
                      ),
                    ),
                  if(state == fs.TaskState.paused)
                    Material(
                      child: IconButton(
                        icon: Icon(Icons.file_upload),
                        onPressed: task.resume,
                      ),
                    )
                ],
              ),
            ));
      },
    );
  }
}