import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:faker/faker.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      appId: dotenv.env['APP_ID']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['PROJECT_ID']!,
      databaseURL: dotenv.env['DATABASE_URL']!,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _nomes = [];
  bool _mostrarFavoritos = false;
  final Faker _faker = Faker();

  @override
  void initState() {
    super.initState();
    _getNomes();
  }

  Future<void> _getNomes() async {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<String, dynamic>> listaNomes = [];
        data.forEach((key, value) {
          listaNomes.add({
            'id': key,
            'nome': value['nome'],
            'sobrenome': value['sobrenome'],
            'favorito': value['favorito'] ?? false,
          });
        });

        setState(() {
          _nomes = listaNomes;
        });
      } else {
        setState(() {
          _nomes = [];
        });
      }
    });
  }

  Future<void> _gerarNomeAleatorio() async {
    String id = _database.push().key ?? "0";
    String nome = _faker.person.firstName();
    String sobrenome = _faker.person.lastName();

    await _database.child(id).set({'nome': nome, 'sobrenome': sobrenome});

    _getNomes();
  }

  Future<void> _deletarNome(String id) async {
    await _database.child(id).remove();
    _getNomes();
  }

  Future<void> _deletarTodos() async {
    await _database.remove();
    _getNomes();
  }

  Future<void> _copiarNome(String nome, String sobrenome) async {
    final text = "$nome $sobrenome";
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _favoritarNome(String id, bool isFavorito) async {
    await _database.child(id).update({'favorito': !isFavorito});
    _getNomes();
  }

  List<Map<String, dynamic>> _getFavoritos() {
    return _nomes.where((nome) => nome['favorito'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Gerador de Nomes",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.9, 
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Colors.deepPurple,
                ], // Gradiente bonito
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4, 
          shadowColor: Colors.black,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _mostrarFavoritos = !_mostrarFavoritos;
                      });
                    },
                    icon: Icon(
                      Icons.star,
                      color: _mostrarFavoritos ? Colors.grey : Colors.yellow,
                    ),
                    label: Text(
                      _mostrarFavoritos ? "Mostrar Todos" : "Favoritos",
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _deletarTodos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text("Limpar"),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _gerarNomeAleatorio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Cor opcional
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 40,
                      ), 
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ), 
                    ),
                    child: Text("Gerar Nome Aleatório"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount:
                      _mostrarFavoritos
                          ? _getFavoritos().length
                          : _nomes.length,
                  itemBuilder: (context, index) {
                    var lista = _mostrarFavoritos ? _getFavoritos() : _nomes;
                    bool isFavorito = _nomes[index]['favorito'] ?? false;
                    return Card(
                      child: ListTile(
                        title: Text(
                          "${lista[index]['nome']} ${lista[index]['sobrenome']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletarNome(lista[index]['id']),
                            ),
                            IconButton(
                              onPressed: () {
                                _copiarNome(
                                  lista[index]['nome'],
                                  lista[index]['sobrenome'],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Nome copiado!")),
                                );
                              },
                              icon: Icon(Icons.copy),
                            ),
                            IconButton(
                              onPressed: () {
                                _favoritarNome(
                                  lista[index]['id'],
                                  _nomes[index]['favorito'],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      lista[index]['favorito']
                                          ? "Removido dos favoritos!"
                                          : "Adicionado aos favoritos!",
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.star,
                                color: isFavorito ? Colors.yellow : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}