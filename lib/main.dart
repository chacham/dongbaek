import 'package:dongbaek/blocs/progress_bloc.dart';
import 'package:dongbaek/blocs/snapshot_bloc.dart';
import 'package:dongbaek/blocs/timer_bloc.dart';
import 'package:dongbaek/services/progress_service.dart';
import 'package:dongbaek/services/schedule_service.dart';
import 'package:dongbaek/utils/datetime_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_schedule_page.dart';
import 'blocs/schedule_bloc.dart';
import 'models/schedule.dart';
import 'models/snapshot.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ScheduleService>(
          create: (BuildContext context) => ScheduleService(),
        ),
        RepositoryProvider<ProgressService>(
          create: (BuildContext context) => ProgressService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ScheduleBloc>(
            create: (BuildContext context) => ScheduleBloc(RepositoryProvider.of<ScheduleService>(context)),
          ),
          BlocProvider<ProgressBloc>(
            create: (BuildContext context) => ProgressBloc(RepositoryProvider.of<ProgressService>(context)),
          ),
          BlocProvider<SnapshotBloc>(
            create: (BuildContext context) => SnapshotBloc(
              RepositoryProvider.of<ScheduleService>(context),
              RepositoryProvider.of<ProgressService>(context),
            ),
          ),
          BlocProvider<TimerBloc>(
            create: (BuildContext context) => TimerBloc(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/addSchedule': (context) => const AddSchedulePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _currentDate = DateTimeUtils.truncateToDay(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerBloc, DateTime>(
      listenWhen: (before, current) {
        return before.day != current.day;
      },
      listener: (context, DateTime dateTime) {
        setState(() {
          _currentDate = DateTimeUtils.truncateToDay(dateTime);
          BlocProvider.of<ScheduleBloc>(context).add(const UpdateScheduleDate());
          BlocProvider.of<ProgressBloc>(context).add(const UpdateProgressDate());
          BlocProvider.of<SnapshotBloc>(context).add(const UpdateSnapshotDate());
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              "${_currentDate.year}/${_currentDate.month}/${_currentDate.day}(${DateTimeUtils.getDayOfWeek(_currentDate)})"),
        ),
        body: BlocBuilder<SnapshotBloc, List<Snapshot>>(builder: (context, List<Snapshot> snapshots) {
          final tiles = snapshots.map((snapshot) {
            final schedule = snapshot.schedule;
            final progress = snapshot.progress;
            final repeatInfo = schedule.repeatInfo;
            Text subtitle;
            if (schedule.repeatInfo is RepeatPerDay) {
              subtitle = Text('${progress.completeTimes.length} / ${(repeatInfo as RepeatPerDay).repeatCount}');
            } else {
              subtitle = Text('${progress.completeTimes.length} / ${(repeatInfo as RepeatPerWeek).repeatCount}');
            }
            return ListTile(
              title: Text(schedule.title + " by " + (schedule.repeatInfo is RepeatPerDay ? "Daily" : "Weekly")),
              subtitle: subtitle,
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  context.read<ScheduleBloc>().add(RemoveSchedule(schedule.id));
                  context.read<SnapshotBloc>().add(const SnapshotDataUpdated());
                },
              ),
              onLongPress: () {
                context.read<ProgressBloc>().add(AddProgress(schedule.id, DateTime.now()));
                context.read<SnapshotBloc>().add(const SnapshotDataUpdated());
              },
            );
          }).toList();
          return ListView.builder(
            itemCount: tiles.length,
            itemBuilder: (BuildContext context, int index) => Card(child: tiles[index]),
          );
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            Navigator.pushNamed(context, "/addSchedule");
          },
          tooltip: 'Add',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
