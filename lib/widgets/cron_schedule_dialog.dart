import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

class CronScheduleDialog extends StatefulWidget {
  final Function(CronSchedule) onScheduleSet;
  final CronSchedule? initialSchedule;

  const CronScheduleDialog({
    super.key,
    required this.onScheduleSet,
    this.initialSchedule,
  });

  @override
  State<CronScheduleDialog> createState() => _CronScheduleDialogState();
}

class _CronScheduleDialogState extends State<CronScheduleDialog> {
  late CronSchedule schedule;
  String? _selectedLabel;
  TimeUnit? _selectedUnit;
  Function(TimeUnit)? _selectedUnitCallback;

  // 为每个时间单位创建独立的控制器
  final Map<String, TextEditingController> _specificControllers = {};
  final Map<String, TextEditingController> _intervalControllers = {};
  final Map<String, TextEditingController> _startControllers = {};
  final Map<String, TextEditingController> _endControllers = {};

  @override
  void initState() {
    super.initState();
    schedule = widget.initialSchedule ?? CronSchedule();
    // 初始化所有时间单位的控制器
    for (final label in ['秒', '分', '时', '日', '月', '周', '年']) {
      _specificControllers[label] = TextEditingController();
      _intervalControllers[label] = TextEditingController();
      _startControllers[label] = TextEditingController();
      _endControllers[label] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // 销毁所有控制器
    for (var controller in _specificControllers.values) {
      controller.dispose();
    }
    for (var controller in _intervalControllers.values) {
      controller.dispose();
    }
    for (var controller in _startControllers.values) {
      controller.dispose();
    }
    for (var controller in _endControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 更新选中单位的控制器值
  void _updateControllers(String label, TimeUnit unit) {
    switch (unit.type) {
      case 'specific':
        _specificControllers[label]?.text = unit.values.join(',');
        break;
      case 'interval':
        _intervalControllers[label]?.text = unit.interval.toString();
        break;
      case 'range':
        _startControllers[label]?.text = unit.start.toString();
        _endControllers[label]?.text = unit.end.toString();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: settings.getSelectedBgColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '设置执行计划',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: settings.getForegroundColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 时间单位选择器容器
            Container(
              decoration: BoxDecoration(
                color: settings.getForegroundColor().withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 时间单位横向排布
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTimeUnitLabel('秒', schedule.second, (value) {
                          setState(() => schedule.second = value);
                        }, settings),
                        _buildTimeUnitLabel('分', schedule.minute, (value) {
                          setState(() => schedule.minute = value);
                        }, settings),
                        _buildTimeUnitLabel('时', schedule.hour, (value) {
                          setState(() => schedule.hour = value);
                        }, settings),
                        _buildTimeUnitLabel('日', schedule.day, (value) {
                          setState(() => schedule.day = value);
                        }, settings),
                        _buildTimeUnitLabel('月', schedule.month, (value) {
                          setState(() => schedule.month = value);
                        }, settings),
                        _buildTimeUnitLabel('周', schedule.weekday, (value) {
                          setState(() => schedule.weekday = value);
                        }, settings),
                        _buildTimeUnitLabel('年', schedule.year, (value) {
                          setState(() => schedule.year = value);
                        }, settings),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 输入区域
                  _buildActiveInput(settings),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cron 表达式预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: settings.getForegroundColor().withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: settings.getSelectedBgColor().withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cron表达式',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schedule.toCronExpression(),
                    style: TextStyle(
                      color: settings.getSelectedBgColor(),
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: settings.getSelectedBgColor(),
                    side: BorderSide(color: settings.getSelectedBgColor()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onScheduleSet(schedule);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.getSelectedBgColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnitLabel(
    String label,
    TimeUnit unit,
    Function(TimeUnit) onChanged,
    ChangeSettings settings,
  ) {
    final isSelected = _selectedLabel == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLabel = isSelected ? null : label;
            _selectedUnit = isSelected ? null : unit;
            _selectedUnitCallback = isSelected ? null : onChanged;
            if (!isSelected) {
              _updateControllers(label, unit);
            }
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(77),
            ),
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unit.toString(),
                style: TextStyle(
                  color: settings.getSelectedBgColor(),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveInput(ChangeSettings settings) {
    if (_selectedLabel == null || _selectedUnit == null || _selectedUnitCallback == null) {
      return Center(
        child: Text(
          '点击上方时间单位进行设置',
          style: TextStyle(
            color: settings.getForegroundColor().withAlpha(128),
          ),
        ),
      );
    }

    // 定义下拉选项
    const dropdownData = ['每', '指定', '间隔', '范围'];
    final selectedValue = _getTypeText(_selectedUnit!.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '设置$_selectedLabel',
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: CommonDropdownWidget(
                dropdownData: dropdownData,
                selectedValue: selectedValue, // 确保这个值在 dropdownData 中存在
                onChangeValue: (value) {
                  final type = _getTypeValue(value);
                  setState(() {
                    final newUnit = TimeUnit(
                      type: type,
                      values: _selectedUnit!.values,
                      start: _selectedUnit!.start,
                      end: _selectedUnit!.end,
                      interval: _selectedUnit!.interval,
                    );
                    _selectedUnit = newUnit;
                    _selectedUnitCallback!(newUnit);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTimeUnitInput(_selectedLabel!, _selectedUnit!, _selectedUnitCallback!, settings),
      ],
    );
  }

  // 添加辅助方法用于转换类型文本和值
  String _getTypeText(String type) {
    switch (type) {
      case 'every':
        return '每';
      case 'specific':
        return '指定';
      case 'interval':
        return '间隔';
      case 'range':
        return '范围';
      default:
        return '每';
    }
  }

  String _getTypeValue(String text) {
    switch (text) {
      case '每':
        return 'every';
      case '指定':
        return 'specific';
      case '间隔':
        return 'interval';
      case '范围':
        return 'range';
      default:
        return 'every';
    }
  }

  Widget _buildTimeUnitInput(
    String label,
    TimeUnit unit,
    Function(TimeUnit) onChanged,
    ChangeSettings settings,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: settings.getSelectedBgColor()),
    );

    switch (unit.type) {
      case 'specific':
        return TextField(
          controller: _specificControllers[label],
          decoration: InputDecoration(
            hintText: '输入具体$label值，多个用逗号分隔',
            hintStyle: TextStyle(color: settings.getForegroundColor().withAlpha(128)),
            enabledBorder: border,
            focusedBorder: border,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(color: settings.getForegroundColor()),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // 只保留数字和逗号
            final cleanValue = value.replaceAll(RegExp(r'[^0-9,]'), '');
            if (cleanValue != value) {
              _specificControllers[label]?.text = cleanValue;
              _specificControllers[label]?.selection = TextSelection.fromPosition(
                TextPosition(offset: cleanValue.length),
              );
            }
            final values = cleanValue.split(',').where((e) => e.isNotEmpty).toList();
            onChanged(TimeUnit(type: unit.type, values: values));
          },
        );

      case 'interval':
        return TextField(
          controller: _intervalControllers[label],
          decoration: InputDecoration(
            hintText: '间隔值',
            hintStyle: TextStyle(color: settings.getForegroundColor().withAlpha(128)),
            enabledBorder: border,
            focusedBorder: border,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(color: settings.getForegroundColor()),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // 只保留数字
            final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanValue != value) {
              _intervalControllers[label]?.text = cleanValue;
              _intervalControllers[label]?.selection = TextSelection.fromPosition(
                TextPosition(offset: cleanValue.length),
              );
            }
            onChanged(TimeUnit(
              type: unit.type,
              interval: int.tryParse(cleanValue) ?? 1,
            ));
          },
        );

      case 'range':
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startControllers[label],
                decoration: InputDecoration(
                  hintText: '开始值',
                  hintStyle: TextStyle(color: settings.getForegroundColor().withAlpha(128)),
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(color: settings.getForegroundColor()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue != value) {
                    _startControllers[label]?.text = cleanValue;
                    _startControllers[label]?.selection = TextSelection.fromPosition(
                      TextPosition(offset: cleanValue.length),
                    );
                  }
                  final newUnit = TimeUnit(
                    type: unit.type,
                    values: _selectedUnit!.values,
                    start: int.tryParse(cleanValue) ?? 0,
                    end: _selectedUnit!.end,
                    interval: _selectedUnit!.interval,
                  );
                  setState(() => _selectedUnit = newUnit);
                  onChanged(newUnit);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: TextStyle(color: settings.getForegroundColor()),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _endControllers[label],
                decoration: InputDecoration(
                  hintText: '结束值',
                  hintStyle: TextStyle(color: settings.getForegroundColor().withAlpha(128)),
                  enabledBorder: border,
                  focusedBorder: border,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(color: settings.getForegroundColor()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue != value) {
                    _endControllers[label]?.text = cleanValue;
                    _endControllers[label]?.selection = TextSelection.fromPosition(
                      TextPosition(offset: cleanValue.length),
                    );
                  }
                  final newUnit = TimeUnit(
                    type: unit.type,
                    values: _selectedUnit!.values,
                    start: _selectedUnit!.start,
                    end: int.tryParse(cleanValue) ?? 0,
                    interval: _selectedUnit!.interval,
                  );
                  setState(() => _selectedUnit = newUnit);
                  onChanged(newUnit);
                },
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class CronSchedule {
  TimeUnit second;
  TimeUnit minute;
  TimeUnit hour;
  TimeUnit day;
  TimeUnit month;
  TimeUnit weekday;
  TimeUnit year;

  CronSchedule({
    TimeUnit? second,
    TimeUnit? minute,
    TimeUnit? hour,
    TimeUnit? day,
    TimeUnit? month,
    TimeUnit? weekday,
    TimeUnit? year,
  })  : second = second ?? TimeUnit(),
        minute = minute ?? TimeUnit(),
        hour = hour ?? TimeUnit(),
        day = day ?? TimeUnit(),
        month = month ?? TimeUnit(),
        weekday = weekday ?? TimeUnit(),
        year = year ?? TimeUnit();

  String toCronExpression() {
    return [second, minute, hour, day, month, weekday, year].map((unit) => unit.toString()).join(' ');
  }

  static CronSchedule fromExpression(String expression) {
    final parts = expression.split(' ');
    if (parts.length != 7) {
      throw const FormatException('Invalid cron expression');
    }

    return CronSchedule(
      second: _parseTimeUnit(parts[0]),
      minute: _parseTimeUnit(parts[1]),
      hour: _parseTimeUnit(parts[2]),
      day: _parseTimeUnit(parts[3]),
      month: _parseTimeUnit(parts[4]),
      weekday: _parseTimeUnit(parts[5]),
      year: _parseTimeUnit(parts[6]),
    );
  }

  static TimeUnit _parseTimeUnit(String value) {
    if (value == '*') {
      return TimeUnit(type: 'every');
    }
    if (value.contains('/')) {
      final parts = value.split('/');
      return TimeUnit(
        type: 'interval',
        interval: int.parse(parts[1]),
      );
    }
    if (value.contains('-')) {
      final parts = value.split('-');
      return TimeUnit(
        type: 'range',
        start: int.parse(parts[0]),
        end: int.parse(parts[1]),
      );
    }
    if (value.contains(',')) {
      return TimeUnit(
        type: 'specific',
        values: value.split(','),
      );
    }
    return TimeUnit(
      type: 'specific',
      values: [value],
    );
  }

  bool matches(DateTime time) {
    return _matchesUnit(time.second, second) &&
        _matchesUnit(time.minute, minute) &&
        _matchesUnit(time.hour, hour) &&
        _matchesUnit(time.day, day) &&
        _matchesUnit(time.month, month) &&
        _matchesUnit(time.weekday, weekday) &&
        _matchesUnit(time.year, year);
  }

  bool _matchesUnit(int value, TimeUnit unit) {
    switch (unit.type) {
      case 'every':
        return true;
      case 'specific':
        return unit.values.map(int.parse).contains(value);
      case 'interval':
        return value % unit.interval == 0;
      case 'range':
        return value >= unit.start && value <= unit.end;
      default:
        return false;
    }
  }

  DateTime getNextExecutionTime() {
    var now = DateTime.now();
    while (!matches(now)) {
      now = now.add(const Duration(seconds: 1));
    }
    return now;
  }
}

class TimeUnit {
  String type;
  List<String> values;
  int start;
  int end;
  int interval;

  TimeUnit({
    this.type = 'every',
    this.values = const [],
    this.start = 0,
    this.end = 0,
    this.interval = 1,
  });

  @override
  String toString() {
    switch (type) {
      case 'every':
        return '*';
      case 'specific':
        return values.join(',');
      case 'interval':
        return '*/$interval';
      case 'range':
        return '$start-$end';
      default:
        return '*';
    }
  }
}
