import 'package:flutter/material.dart';

import '../inspection_report_model.dart';
import 'package:claimscope_clean/Screens/commercial_roof_section_screen.dart';

class CommercialBuildingDetailScreen extends StatefulWidget {
  final String plan;
  final InspectionReport report;
  final int buildingIndex;

  const CommercialBuildingDetailScreen({
    super.key,
    required this.plan,
    required this.report,
    required this.buildingIndex,
  });

  @override
  State<CommercialBuildingDetailScreen> createState() => _CommercialBuildingDetailScreenState();
}

class _CommercialBuildingDetailScreenState extends State<CommercialBuildingDetailScreen> {
  late final CommercialBuildingData building;

  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    building = widget.report.commercialBuildings[widget.buildingIndex];

    _nameController.text = building.name ?? '';
    _streetController.text = building.streetAddress ?? '';
    _notesController.text = building.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _sync() {
    building.name = _nameController.text.trim().isEmpty
        ? null
        : _nameController.text.trim();

    building.streetAddress = _streetController.text.trim().isEmpty
        ? null
        : _streetController.text.trim();

    building.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
  }

  void _addRoofSection() {
    _sync();
    setState(() {
      building.roofs.add(CommercialRoofSectionData());
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommercialRoofSectionScreen(
          plan: widget.plan,
          report: widget.report,
          buildingIndex: widget.buildingIndex,
          roofIndex: building.roofs.length - 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = building.displayName(widget.buildingIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Building name (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Different address than main?'),
            value: building.differentAddress,
            onChanged: (v) {
              setState(() {
                building.differentAddress = v ?? false;
                if (!building.differentAddress) {
                  _streetController.clear();
                  building.streetAddress = null;
                }
              });
            },
          ),
          if (building.differentAddress) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street address',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _sync(),
            ),
          ],
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Does this building have more than one roof cover type?'),
            value: building.hasMultipleRoofTypes,
            onChanged: (v) {
              setState(() {
                building.hasMultipleRoofTypes = v ?? false;
                if (!building.hasMultipleRoofTypes) {
                  if (building.roofs.isEmpty) {
                    building.roofs.add(CommercialRoofSectionData());
                  } else if (building.roofs.length > 1) {
                    building.roofs = [building.roofs.first];
                  }
                } else {
                  if (building.roofs.isEmpty) {
                    building.roofs.add(CommercialRoofSectionData());
                  }
                }
              });
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addRoofSection,
            child: Text(building.roofs.isEmpty ? 'Add roof section' : 'Add another roof section'),
          ),
          const SizedBox(height: 12),
          if (building.roofs.isNotEmpty) ...[
            const Divider(),
            const Text('Roof sections', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...building.roofs.asMap().entries.map((entry) {
              final idx = entry.key;
              final roof = entry.value;
              final roofName = (roof.roofLabel ?? '').trim().isEmpty
                  ? 'Roof ${idx + 1}'
                  : roof.roofLabel!.trim();

              final subtitle = [roof.roofType, roof.roofSubType]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(' - ');

              return Card(
                child: ListTile(
                  title: Text(roofName),
                  subtitle: Text(subtitle.isEmpty ? 'Not set' : subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _sync();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommercialRoofSectionScreen(
                          plan: widget.plan,
                          report: widget.report,
                          buildingIndex: widget.buildingIndex,
                          roofIndex: idx,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Building notes (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _sync(),
          ),
        ],
      ),
    );
  }
}
