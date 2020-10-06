import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController =
      TextEditingController(); //Pegar a informação do texto, manipular texto TextField

  List _toDoList = [];

  Map<String, dynamic>
      _lastRemoved; //mapa do item que acabou de remover para recupera -lo
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    }); //faz a leitura dos dados, função para retornar a leitura dos dados
  }

  void _addToDo() {
    setState(() {
      //setState Atualiza a tela após um evento, nesse caso inserir
      Map<String, dynamic> newToDo = Map(); //Para manipular o mapeamento JSON
      newToDo["title"] =
          _toDoController.text; //Pata pegar o texto do Text field
      _toDoController.text =
          ""; // Após adicionar o texto o campo ficará vazio novamente
      newToDo["ok"] =
          false; // Inicia como falso, só será verdadeiro quando checarmos a tarefa
      _toDoList.add(newToDo); //TErminando de adicionar o elemento map

      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1, 7, 1),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller:
                          _toDoController, //controller adicionado para manipulação de texto conforme declarado acima
                      decoration: InputDecoration(
                          labelText: "Nova tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed:
                        _addToDo, //Chamando função para adicionar os itens em JSON
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,
                ),
              ),
            ),
          ],
        ));
  }

//metodo responsavel por adicionar os itens na lista
  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection
          .startToEnd, //direção para arrastar o item para exclui -lo da esquerda para direita
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          //c é a variavel para alterar o estado do item
          setState(() {
            _toDoList[index]["ok"] = c; //altera o estado do item do check
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved =
              Map.from(_toDoList[index]); //duplicando o item após remove -lo
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                //função anonima para reincluir o item na lista
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData(); //salva os dados recuperados
                });
              },
            ),
            duration: Duration(seconds: 2), //duração do snackbar
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack); //para exibir o snackbar
        });
      },
    );
  }

//-----------------funções para o armazenamento dos dados JSON--------------------
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
