import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdelia_core/health/blood_type.dart';

class BloodPicker extends StatefulWidget {
  final ValueChanged<int> onBloodChanged;
  final List<BloodType> blood_type;
  final int blood_id;

  const BloodPicker({
    super.key,
    required this.onBloodChanged,
    required this.blood_type,
    required this.blood_id,
  });

  @override
  _BloodPickerState createState() => _BloodPickerState();
}

class _BloodPickerState extends State<BloodPicker> {
  int _selectedBloodIndex = 0;

  @override
  void initState() {
    _selectedBloodIndex = widget.blood_type
        .indexWhere((blood) => blood.id_blood_type == widget.blood_id);
    widget.onBloodChanged(
      widget.blood_type[_selectedBloodIndex].id_blood_type,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          // tileColor: Colors.blue[50],
          title: Text(
            widget.blood_type[_selectedBloodIndex].blood_type_desc,
          ),
          onTap: () {
            _showPicker(context);
          },
          // trailing: getAppUserbloodIcon(
          //   widget.blood_type[_selectedBloodIndex].recipe_provider_type_id,
          // ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int index) {
              if (mounted) {
                setState(() {
                  _selectedBloodIndex = index;
                });
              }
              // //log('${widget.blood_type[index].recipe_provider_type_id}');

              widget.onBloodChanged(
                widget.blood_type[index].id_blood_type,
              );
            },
            children: widget.blood_type.map((BloodType blood) {
              return Center(child: Text(blood.blood_type_desc));
            }).toList(),
          ),
        );
      },
    );
  }
}
