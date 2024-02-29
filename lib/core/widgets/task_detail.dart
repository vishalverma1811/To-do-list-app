import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo_list_app/core/widgets/task_provider.dart';
import '../../task_list.dart';
import '../models/task_model.dart';
import 'priority_provider.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  TaskDetailsPage({required this.task});

  @override
  _TaskDetailsPageState createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late String defaultPriority;
  late String selectedPriority = '';
  List<String> priorities = [];
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  late DateTime selectedDate;
  final PriorityProvider priorityProvider = PriorityProvider();


  void initializePriority() {
    for (int i = 0; i < priorityProvider.priorities.length; i++) {
      priorities.add(priorityProvider.priorities[i].priority);
    }
  }

  @override
  void initState() {
    super.initState();
    initializePriority();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    defaultPriority = widget.task.priority;
    selectedDate = widget.task.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: defaultPriority,
              onChanged: (value) {
                selectedPriority = value!;
              },
              items: priorities.map((priority) {
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "Due date of Task",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : ''}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.36),
                    GestureDetector(
                      onTap: () async {
                        final DateTime currentDate = DateTime.now();
                        DateTime dateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day,);

                        final DateTime? datePicked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: dateOnly,
                          lastDate: DateTime(2100),
                        );
                        await validate_date(context, datePicked!, dateOnly);
                      },
                      child: Icon(Icons.date_range_rounded, size: 24, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            TextField(
              controller: timeController,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedDate != null ? DateFormat('HH:mm').format(selectedDate!) : ''}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.36),
                    GestureDetector(
                      onTap: () async {
                        await _selectTime(context, selectedDate);
                      },
                      child: Icon(Icons.access_time_rounded, size: 24, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Task updatedTask = Task(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      priority: selectedPriority == '' ? defaultPriority : selectedPriority,
                      dueDate: selectedDate,
                    );

                    TaskProvider().updateTask(TaskProvider().tasks.indexOf(widget.task), updatedTask);
                    Get.offAll(TaskList());
                  } ,
                  child: Text('Save'),
                ),
                SizedBox(width: 15,),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Are you sure?"),
                          content: Text("Do you really want to delete this task?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("No"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                TaskProvider().deleteTask(TaskProvider().tasks.indexOf(widget.task));
                                Get.offAll(TaskList());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                'Yes',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> validate_date(BuildContext context, DateTime datePicked, DateTime dateOnly) async {
    if (datePicked != null && datePicked != selectedDate) {
      if (datePicked == dateOnly || datePicked.isAfter(dateOnly)) {
        setState(() {
          selectedDate = datePicked;
        });

        print('valid date');
      }
    }
  }

  Future<void> _selectTime(BuildContext context, [DateTime? initialTime]) async {
    final TimeOfDay? timePicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime ?? DateTime.now().add(Duration(hours: 1))),
    );

    if (timePicked != null) {
      DateTime selectedDateTime = DateTime(
        selectedDate?.year ?? DateTime.now().year,
        selectedDate?.month ?? DateTime.now().month,
        selectedDate?.day ?? DateTime.now().day,
        timePicked.hour,
        timePicked.minute,
      );

      setState(() {
        selectedDate = selectedDateTime;
        dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
      });
    }
  }
}

