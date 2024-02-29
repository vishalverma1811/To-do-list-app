import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/models/priority_model.dart';
import 'core/models/task_model.dart';
import 'core/widgets/add_task.dart';
import 'core/widgets/priority_provider.dart';
import 'core/widgets/task_detail.dart';
import 'main.dart';

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State createState() => _ListTile();
}

class InnerList {
  String priority;
  List<Task> tasks;

  InnerList({
    required this.priority,
    required this.tasks,
  });
}


class _ListTile extends State<TaskList> {
  final PriorityProvider priorityProvider = PriorityProvider();
  List<InnerList> _lists = [];
  late List<Task> tasks;
  late List<Pref> priorities;
  String _searchQuery = '';
  List<Task> _searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchDataFromHive();
  }

  Future<void> fetchDataFromHive() async {
    tasks = tasksBox.values.toList();
    priorities = priorityBox.values.toList();

    if (tasks.isEmpty) {
      final priorityNames = [
        'All Tasks',
        ...priorities.map((priority) => priority.priority).toList()
      ];

      setState(() {
        _lists = List.generate(priorityNames.length, (priorityIndex) {
          final priorityName = priorityNames[priorityIndex];
          final priorityTasks = (priorityName == 'All Tasks')
              ? tasks
              : tasks.where((task) => task.priority == priorityName).toList();

          return InnerList(
            tasks: priorityTasks,
            priority: priorityName,
          );
        });
      });
    } else {
      final priorityNames = [
        'All Tasks',
        ...priorities.map((priority) => priority.priority).toList()
      ];

      setState(() {
        _lists = List.generate(priorityNames.length, (priorityIndex) {
          final priorityName = priorityNames[priorityIndex];
          final priorityTasks = (priorityName == 'All Tasks')
              ? tasks
              : tasks.where((task) => task.priority == priorityName).toList();

          return InnerList(
            tasks: priorityTasks,
            priority: priorityName,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Do List'),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SearchBar(
                hintText: 'Search Task',
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                    _searchResults = tasks.where((task) => task.title.toLowerCase().contains(query.toLowerCase())).toList();
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Color(0xFFB0D8DA),
                  ),
                  child: _searchResults.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('No results found'),
                      )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            var task = _searchResults[index];
                        return ListTile(
                          title: Text(task.title),
                          onTap: () {
                            Get.to(TaskDetailsPage(task: task))?.then((value){
                            setState(() {
                              _searchQuery = '';
                            });
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.78,
                child: DragAndDropLists(
                  children: List.generate(_lists.length, (index) => _buildList(index)),
                  onItemReorder: _onItemReorder,
                  onListReorder: _onListReorder,
                  removeTopPadding: true,

                  // listGhost is mandatory when using expansion tiles to prevent multiple widgets using the same globalkey
                  listGhost: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 30.0, horizontal: 100.0),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        child: const Icon(Icons.add_box),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Get.to(AddTaskPage());
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  _buildList(int outerIndex) {
    var innerList = _lists[outerIndex];
    return DragAndDropListExpansion(
      title: Text(innerList.priority),
      children: List.generate(
        innerList.tasks.length,
            (index) => _buildItem(innerList.tasks[index]),
      ),
      listKey: ObjectKey(innerList.priority),
    );
  }

  _buildItem(Task task) {
    Color itemColor;

      DateTime currentDate = DateTime.now();
      DateTime taskDueDate = task.dueDate;

      if (taskDueDate.isBefore(currentDate)) {
        // Task due date is in the past
        itemColor = Colors.red;
      } else if (taskDueDate.day == currentDate.day &&
          taskDueDate.month == currentDate.month &&
          taskDueDate.year == currentDate.year) {
        // Task due date is today
        itemColor = Colors.orange;
      } else {
        // Default color for other cases
        itemColor = Colors.black;
      }
    return DragAndDropItem(
      child: ListTile(
        title: Text(task.title, style: TextStyle(color: itemColor),),
        onTap: () {
          print(task.title);
          Get.to(TaskDetailsPage(task: task));
        },
      ),
    );
  }


  _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex,
      int newListIndex) {
    setState(() {
      if (oldListIndex == newListIndex) {
        var innerList = _lists[oldListIndex];
        var movedList = innerList.tasks.removeAt(oldItemIndex);
        innerList.tasks.insert(newItemIndex, movedList);

        List<Task> listToAdd = innerList.tasks;
        for (Task task in listToAdd) {
          print(task.title);
        }

        int i = 0;
        tasks.where((element) =>
        element.priority == _lists[oldListIndex].priority)
            .forEach((element1) {
          tasksBox.putAt(tasks.indexOf(element1), listToAdd[i]);
          i++;
        });
      } else {
        if (_lists[oldListIndex].priority == 'All Tasks' ||
            _lists[newListIndex].priority == 'All Tasks') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Drag and Drop')),
          );
        }
        else {
          var innerList = _lists[oldListIndex];
          var innerList2 = _lists[newListIndex];
          var movedList = innerList.tasks.removeAt(oldItemIndex);
          movedList.priority = innerList2.priority;
          innerList2.tasks.insert(newItemIndex, movedList);
          tasks
              .where((element) =>
          element.title == innerList2.tasks[newItemIndex].title)
              .forEach((element) {
            int index = tasks.indexOf(element);
            print(index);
            tasksBox.putAt(index, element);
          });
        }
      }
    });
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _lists.removeAt(oldListIndex);
      _lists.insert(newListIndex, movedList);

      List<String> priorityToAdd = [];
      for (int i = 0; i < _lists.length; i++) {
        var innerList = _lists[i];
        priorityToAdd.add(innerList.priority);
      }
      priorityToAdd.removeWhere((priority) => priority == 'All Tasks');
      print(priorityToAdd);
      priorityBox.deleteAll(priorityBox.keys);
      for (String i in priorityToAdd) {
        priorityBox.add(Pref(priority: i));
      }
    });
  }
}

