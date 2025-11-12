import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

part 'main.g.dart';

// -----------------------------
// Modelo e Adapter (Hive)
// -----------------------------
class Task extends HiveObject {
  String title;
  String? notes;
  bool done;
  DateTime createdAt;

  Task({
    required this.title,
    this.notes,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Construtor para Sembast
  Task.fromMap(Map<String, dynamic> map)
      : title = map['title'] as String,
        notes = map['notes'] as String?,
        done = map['done'] as bool,
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'done': done,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

// -----------------------------
// Modelo para Isar
// -----------------------------
@collection
class TaskIsar {
  Id id = Isar.autoIncrement;
  
  late String title;
  String? notes;
  late bool done;
  late DateTime createdAt;

  TaskIsar();

  // Converter de/para Task
  Task toTask() {
    return Task(
      title: title,
      notes: notes,
      done: done,
      createdAt: createdAt,
    );
  }

  static TaskIsar fromTask(Task task) {
    return TaskIsar()
      ..title = task.title
      ..notes = task.notes
      ..done = task.done
      ..createdAt = task.createdAt;
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final title = reader.readString();
    final hasNotes = reader.readBool();
    final notes = hasNotes ? reader.readString() : null;
    final done = reader.readBool();
    final createdAtMillis = reader.readInt();

    return Task(
      title: title,
      notes: notes,
      done: done,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
    writer.writeBool(obj.done);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

// -----------------------------
// Interface Abstrata para Bancos
// -----------------------------
abstract class DatabaseInterface {
  String get name;
  Future<void> initialize();
  Future<void> insertTask(Task task);
  Future<List<Task>> getAllTasks();
  Future<void> updateTask(Task task);
  Future<void> deleteTask(Task task);
  Future<List<Task>> getCompletedTasks();
  Future<void> clear();
  Future<void> close();
}

// -----------------------------
// Implementação Isar
// -----------------------------
class IsarDatabase implements DatabaseInterface {
  late Isar isar;

  @override
  String get name => 'Isar';

  @override
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [TaskIsarSchema],
      directory: dir.path,
      name: 'tasks_isar_benchmark',
    );
  }

  @override
  Future<void> insertTask(Task task) async {
    await isar.writeTxn(() async {
      await isar.taskIsars.put(TaskIsar.fromTask(task));
    });
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final tasks = await isar.taskIsars.where().findAll();
    return tasks.map((t) => t.toTask()).toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    // No Isar, precisamos encontrar o ID original
    final isarTasks = await isar.taskIsars.where().findAll();
    if (isarTasks.isNotEmpty) {
      final isarTask = isarTasks.first;
      isarTask.title = task.title;
      isarTask.notes = task.notes;
      isarTask.done = task.done;
      
      await isar.writeTxn(() async {
        await isar.taskIsars.put(isarTask);
      });
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    final tasks = await isar.taskIsars.where().findAll();
    if (tasks.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.taskIsars.delete(tasks.first.id);
      });
    }
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final tasks = await isar.taskIsars.filter().doneEqualTo(true).findAll();
    return tasks.map((t) => t.toTask()).toList();
  }

  @override
  Future<void> clear() async {
    await isar.writeTxn(() async {
      await isar.taskIsars.clear();
    });
  }

  @override
  Future<void> close() async {
    await isar.close();
  }
}

// -----------------------------
// Implementação Sembast
// -----------------------------
class SembastDatabase implements DatabaseInterface {
  late Database _db;
  late StoreRef<int, Map<String, dynamic>> _store;

  @override
  String get name => 'Sembast';

  @override
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/tasks_sembast_benchmark.db';
    
    // Deletar banco existente para limpar
    try {
      await File(dbPath).delete();
    } catch (_) {}
    
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _store = intMapStoreFactory.store('tasks');
  }

  @override
  Future<void> insertTask(Task task) async {
    await _store.add(_db, task.toMap());
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final records = await _store.find(_db);
    return records.map((record) => Task.fromMap(record.value)).toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    final records = await _store.find(_db);
    if (records.isNotEmpty) {
      await _store.record(records.first.key).update(_db, task.toMap());
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    final records = await _store.find(_db);
    if (records.isNotEmpty) {
      await _store.record(records.first.key).delete(_db);
    }
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final finder = Finder(
      filter: Filter.equals('done', true),
    );
    final records = await _store.find(_db, finder: finder);
    return records.map((record) => Task.fromMap(record.value)).toList();
  }

  @override
  Future<void> clear() async {
    await _store.delete(_db);
  }

  @override
  Future<void> close() async {
    await _db.close();
  }
}
class HiveDatabase implements DatabaseInterface {
  late Box<Task> tasksBox;

  @override
  String get name => 'Hive';

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    tasksBox = await Hive.openBox<Task>('tasks_benchmark');
  }

  @override
  Future<void> insertTask(Task task) async {
    await tasksBox.add(task);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return tasksBox.values.toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    await task.save();
  }

  @override
  Future<void> deleteTask(Task task) async {
    await task.delete();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    return tasksBox.values.where((t) => t.done).toList();
  }

  @override
  Future<void> clear() async {
    await tasksBox.clear();
  }

  @override
  Future<void> close() async {
    await tasksBox.close();
  }
}

// -----------------------------
// Resultados do Benchmark
// -----------------------------
class BenchmarkResult {
  final String operation;
  final Duration duration;
  final int itemCount;

  BenchmarkResult({
    required this.operation,
    required this.duration,
    required this.itemCount,
  });

  double get milliseconds => duration.inMicroseconds / 1000;
  double get itemsPerSecond => itemCount / (duration.inMilliseconds / 1000);
}

// -----------------------------
// Executor de Benchmark
// -----------------------------
class DatabaseBenchmark {
  final DatabaseInterface database;
  final List<BenchmarkResult> results = [];

  DatabaseBenchmark(this.database);

  Future<void> runAllTests({
    required int writeCount,
    required int readCount,
    required Function(String) onProgress,
  }) async {
    results.clear();
    
    onProgress('Inicializando banco de dados...');
    await database.initialize();
    await database.clear();

    // Teste 1: Inserções sequenciais
    onProgress('Teste 1/6: Inserindo $writeCount tarefas...');
    await _testInserts(writeCount);

    // Teste 2: Leituras sequenciais
    onProgress('Teste 2/6: Lendo todas as tarefas...');
    await _testReadAll(readCount);

    // Teste 3: Buscas com filtro
    onProgress('Teste 3/6: Buscando tarefas concluídas...');
    await _testFilteredQuery(readCount);

    // Teste 4: Atualizações
    onProgress('Teste 4/6: Atualizando tarefas...');
    await _testUpdates(min(100, writeCount));

    // Teste 5: Deleções
    onProgress('Teste 5/6: Deletando tarefas...');
    await _testDeletes(min(100, writeCount));

    // Teste 6: Operações mistas
    onProgress('Teste 6/6: Operações mistas...');
    await _testMixedOperations(min(200, writeCount));

    onProgress('Benchmark concluído!');
  }

  Future<void> _testInserts(int count) async {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < count; i++) {
      final task = Task(
        title: 'Tarefa de teste $i',
        notes: 'Notas da tarefa $i com algum texto adicional',
        done: i % 3 == 0,
        createdAt: DateTime.now().subtract(Duration(days: i % 30)),
      );
      await database.insertTask(task);
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Inserções Sequenciais',
      duration: stopwatch.elapsed,
      itemCount: count,
    ));
  }

  Future<void> _testReadAll(int iterations) async {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < iterations; i++) {
      await database.getAllTasks();
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Leituras Completas',
      duration: stopwatch.elapsed,
      itemCount: iterations,
    ));
  }

  Future<void> _testFilteredQuery(int iterations) async {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < iterations; i++) {
      await database.getCompletedTasks();
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Buscas com Filtro',
      duration: stopwatch.elapsed,
      itemCount: iterations,
    ));
  }

  Future<void> _testUpdates(int count) async {
    final tasks = await database.getAllTasks();
    if (tasks.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < min(count, tasks.length); i++) {
      final task = tasks[i];
      task.done = !task.done;
      task.title = '${task.title} - Atualizado';
      await database.updateTask(task);
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Atualizações',
      duration: stopwatch.elapsed,
      itemCount: min(count, tasks.length),
    ));
  }

  Future<void> _testDeletes(int count) async {
    final tasks = await database.getAllTasks();
    if (tasks.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < min(count, tasks.length); i++) {
      await database.deleteTask(tasks[i]);
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Deleções',
      duration: stopwatch.elapsed,
      itemCount: min(count, tasks.length),
    ));
  }

  Future<void> _testMixedOperations(int count) async {
    final random = Random();
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < count; i++) {
      final operation = random.nextInt(4);
      
      switch (operation) {
        case 0: // Insert
          await database.insertTask(Task(
            title: 'Tarefa mista $i',
            done: false,
          ));
          break;
        case 1: // Read
          await database.getAllTasks();
          break;
        case 2: // Update
          final tasks = await database.getAllTasks();
          if (tasks.isNotEmpty) {
            final task = tasks[random.nextInt(tasks.length)];
            task.done = !task.done;
            await database.updateTask(task);
          }
          break;
        case 3: // Query
          await database.getCompletedTasks();
          break;
      }
    }
    
    stopwatch.stop();
    results.add(BenchmarkResult(
      operation: 'Operações Mistas',
      duration: stopwatch.elapsed,
      itemCount: count,
    ));
  }

  Future<void> cleanup() async {
    await database.clear();
    await database.close();
  }
}

// -----------------------------
// Interface Gráfica
// -----------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Benchmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const BenchmarkPage(),
    );
  }
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  DatabaseInterface? selectedDatabase;
  final List<DatabaseInterface> databases = [
    HiveDatabase(),
    IsarDatabase(),
    SembastDatabase(),
    // Adicione outras implementações aqui:
    // ObjectBoxDatabase(),
    // RxDBDatabase(),
    // NitriteDatabase(),
  ];

  bool isRunning = false;
  String currentProgress = '';
  List<BenchmarkResult>? results;
  
  int writeCount = 1000;
  int readCount = 100;

  Future<void> _runBenchmark() async {
    if (selectedDatabase == null) return;

    setState(() {
      isRunning = true;
      currentProgress = 'Iniciando...';
      results = null;
    });

    final benchmark = DatabaseBenchmark(selectedDatabase!);
    
    try {
      await benchmark.runAllTests(
        writeCount: writeCount,
        readCount: readCount,
        onProgress: (progress) {
          setState(() {
            currentProgress = progress;
          });
        },
      );

      setState(() {
        results = benchmark.results;
        isRunning = false;
        currentProgress = 'Concluído!';
      });

      await benchmark.cleanup();
    } catch (e) {
      setState(() {
        isRunning = false;
        currentProgress = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Benchmark'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seleção de banco de dados
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o Banco de Dados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<DatabaseInterface>(
                      value: selectedDatabase,
                      hint: const Text('Escolha um banco de dados'),
                      isExpanded: true,
                      items: databases.map((db) {
                        return DropdownMenuItem(
                          value: db,
                          child: Text(db.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDatabase = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configurações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Inserções',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: writeCount.toString(),
                            ),
                            onChanged: (value) {
                              writeCount = int.tryParse(value) ?? 1000;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Leituras',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: readCount.toString(),
                            ),
                            onChanged: (value) {
                              readCount = int.tryParse(value) ?? 100;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão executar
            ElevatedButton.icon(
              onPressed: selectedDatabase == null || isRunning
                  ? null
                  : _runBenchmark,
              icon: isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(isRunning ? 'Executando...' : 'Executar Benchmark'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),

            // Progress
            if (currentProgress.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    currentProgress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Resultados
            if (results != null) ...[
              const Text(
                'Resultados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: results!.length,
                    itemBuilder: (context, index) {
                      final result = results![index];
                      return ListTile(
                        title: Text(result.operation),
                        subtitle: Text(
                          '${result.itemCount} operações em ${result.milliseconds.toStringAsFixed(2)}ms',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${result.itemsPerSecond.toStringAsFixed(0)} ops/s',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '${(result.milliseconds / result.itemCount).toStringAsFixed(3)}ms/op',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}