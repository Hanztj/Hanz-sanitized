import 'package:flutter/material.dart';

import '../inspection_report_model.dart';
import 'package:claimscope_clean/Screens/commercial_building_details_screen.dart';

class CommercialBuildingsScreen extends StatefulWidget {
  final String plan;
  final InspectionReport report;

  const CommercialBuildingsScreen({
    super.key,
    required this.plan,
    required this.report,
  });

  @override
  State<CommercialBuildingsScreen> createState() => _CommercialBuildingsScreenState();
}

class _CommercialBuildingsScreenState extends State<CommercialBuildingsScreen> {
  final _countController = TextEditingController(text: '1');

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _createBuildings() {
    final n = int.tryParse(_countController.text.trim());
    if (n == null || n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of buildings.')),
      );
      return;
    }

    setState(() {
      widget.report.commercialBuildings =
          List.generate(n, (_) => CommercialBuildingData());
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommercialBuildingDetailScreen(
          plan: widget.plan,
          report: widget.report,
          buildingIndex: 0,
        ),
      ),
    );
  }

  void _addAnotherBuilding() {
    setState(() {
      widget.report.commercialBuildings.add(CommercialBuildingData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial Buildings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How many buildings are on this project?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of buildings',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _createBuildings,
              child: const Text('Continue'),
            ),
            const SizedBox(height: 16),
            if (widget.report.commercialBuildings.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buildings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _addAnotherBuilding,
                    child: const Text('Add another building'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.report.commercialBuildings.length,
                  itemBuilder: (ctx, idx) {
                    final b = widget.report.commercialBuildings[idx];
                    return Card(
                      child: ListTile(
                        title: Text(b.displayName(idx)),
                        subtitle: Text(
                          b.roofs.isEmpty
                              ? 'Not started'
                              : '${b.roofs.length} roof section(s)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommercialBuildingDetailScreen(
                                plan: widget.plan,
                                report: widget.report,
                                buildingIndex: idx,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

