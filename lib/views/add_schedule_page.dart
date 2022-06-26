import 'package:dongbaek/blocs/snapshot_bloc.dart';
import 'package:dongbaek/models/schedule.dart';
import 'package:dongbaek/utils/datetime_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final GlobalKey<FormState> _addScheduleFormKey = GlobalKey<FormState>();

  String _title = "";

  RepeatInfo _repeatInfo = Once(DateTimeUtils.truncateToDay(DateTime.now()));

  static RepeatInfo _getDefaultRepeatInfo(Type type) {
    switch (type) {
      case Once:
        return Once(DateTimeUtils.currentDay());
      case OnceByInterval:
        return OnceByInterval(DateTimeUtils.currentDay(), 7);
      case QuantityByPeriod:
        return QuantityByPeriod(DateTimeUtils.currentDay(), 7, 1);
      case DurationByPeriod:
        return DurationByPeriod(DateTimeUtils.currentDay(), 7, const Duration(minutes: 30));
      default:
        throw UnimplementedError("INVALID_REPEAT_INFO_TYPE $type");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Schedule")),
      body: Form(
        key: _addScheduleFormKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              onSaved: (newValue) => _title = newValue ?? "",
            ),
            DropdownButton<Type>(
              value: _repeatInfo.runtimeType,
              items: RepeatInfo.getTypes().map<DropdownMenuItem<Type>>((Type i) {
                return DropdownMenuItem<Type>(
                  value: i,
                  child: Text(i.toString()),
                );
              }).toList(),
              onChanged: (Type? value) {
                if (value != null) {
                  setState(() {
                    _repeatInfo = _getDefaultRepeatInfo(value);
                  });
                }
              },
            ),
            _buildRepeatInfoForm(context),
            ElevatedButton(
              onPressed: () {
                _addScheduleFormKey.currentState!.save();
                context.read<SnapshotBloc>().add(AddSchedule(_title, _repeatInfo.startDate, _repeatInfo));
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatInfoForm(BuildContext context) {
    final startDate = _repeatInfo.startDate;
    return Column(
      children: [
        ListTile(
          leading: const Text("Start Date :"),
          title: InkWell(
            child: Text(
                "${startDate.year}. ${startDate.month}. ${startDate.day}. (${DateTimeUtils.getDayOfWeek(startDate).shortName})"),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTimeUtils.truncateToDay(DateTime.now()),
                firstDate: DateTimeUtils.truncateToDay(DateTime.now()),
                lastDate: DateTime.now().add(const Duration(days: 365000)),
              );
              if (selectedDate != null) {
                setState(() {
                  if (_repeatInfo is Once) {
                    _repeatInfo = Once.withBase(_repeatInfo as Once, startDate: selectedDate);
                    return;
                  }
                  if (_repeatInfo is OnceByInterval) {
                    _repeatInfo = OnceByInterval.withBase(_repeatInfo as OnceByInterval, startDate: selectedDate);
                    return;
                  }
                  if (_repeatInfo is QuantityByPeriod) {
                    _repeatInfo = QuantityByPeriod.withBase(_repeatInfo as QuantityByPeriod, startDate: selectedDate);
                    return;
                  }
                  if (_repeatInfo is DurationByPeriod) {
                    _repeatInfo = DurationByPeriod.withBase(_repeatInfo as DurationByPeriod, startDate: selectedDate);
                    return;
                  }
                });
              }
            },
          ),
        ),
        _buildRepeatInfoDetailForm(context),
      ],
    );
  }

  Widget _buildRepeatInfoDetailForm(BuildContext context) {
    if (_repeatInfo is Once) {
      return Container();
    }
    if (_repeatInfo is OnceByInterval) {
      final onceByInterval = _repeatInfo as OnceByInterval;
      return Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            onSaved: (intervalDaysStrVal) {
              final intervalDays = int.tryParse(intervalDaysStrVal ?? "NaN");
              if (intervalDays == null) {
                return;
              }
              setState(() {
                _repeatInfo = OnceByInterval.withBase(onceByInterval, intervalDays: intervalDays);
              });
            },
          ),
        ],
      );
    }
    if (_repeatInfo is QuantityByPeriod) {
      final quantityByPeriod = _repeatInfo as QuantityByPeriod;
      return Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            onSaved: (periodDaysStrVal) {
              final periodDays = int.tryParse(periodDaysStrVal ?? "NaN");
              if (periodDays == null) {
                return;
              }
              setState(() {
                _repeatInfo = QuantityByPeriod.withBase(quantityByPeriod, periodDays: periodDays);
              });
            },
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            onSaved: (quantityStrVal) {
              final quantity = int.tryParse(quantityStrVal ?? "NaN");
              if (quantity == null) {
                return;
              }
              setState(() {
                _repeatInfo = QuantityByPeriod.withBase(quantityByPeriod, quantity: quantity);
              });
            },
          ),
        ],
      );
    }
    if (_repeatInfo is DurationByPeriod) {
      final durationByPeriod = _repeatInfo as DurationByPeriod;
      return Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            onSaved: (periodDaysStrVal) {
              final periodDays = int.tryParse(periodDaysStrVal ?? "NaN");
              if (periodDays == null) {
                return;
              }
              setState(() {
                _repeatInfo = DurationByPeriod.withBase(durationByPeriod, periodDays: periodDays);
              });
            },
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            onSaved: (minutesStrVal) {
              final minutes = int.tryParse(minutesStrVal ?? "NaN");
              if (minutes == null) {
                return;
              }
              setState(() {
                _repeatInfo = DurationByPeriod.withBase(durationByPeriod, duration: Duration(minutes: minutes));
              });
            },
          ),
        ],
      );
    }
    throw UnimplementedError("INVALID_REPEAT_INFO_TYPE ${_repeatInfo.runtimeType}");
  }
}
