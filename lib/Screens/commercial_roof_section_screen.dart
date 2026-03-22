import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../catalogs/roof_catalog.dart';
import '../inspection_report_model.dart';
import '../utils/photo_labels.dart';

class CommercialRoofSectionScreen extends StatefulWidget {
  final String plan;
  final InspectionReport report;
  final int buildingIndex;
  final int roofIndex;

  const CommercialRoofSectionScreen({
    super.key,
    required this.plan,
    required this.report,
    required this.buildingIndex,
    required this.roofIndex,
  });

  @override
  State<CommercialRoofSectionScreen> createState() => _CommercialRoofSectionScreenState();
}

class _CommercialRoofSectionScreenState extends State<CommercialRoofSectionScreen> {
  late final CommercialRoofSectionData roof;

  final _picker = ImagePicker();

  final _roofLabelController = TextEditingController();
  final _pitchController = TextEditingController();
  final _deckOtherController = TextEditingController();
  final _coverOtherController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final building = widget.report.commercialBuildings[widget.buildingIndex];
    roof = building.roofs[widget.roofIndex];

    _roofLabelController.text = roof.roofLabel ?? '';
    _pitchController.text = roof.pitch ?? '';
    _deckOtherController.text = roof.deckTypeOtherSpecify ?? '';
    _coverOtherController.text = roof.coverBoardOtherSpecify ?? '';
    _notesController.text = roof.notes ?? '';
  }

  @override
  void dispose() {
    _roofLabelController.dispose();
    _pitchController.dispose();
    _deckOtherController.dispose();
    _coverOtherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFlatSystem => roof.roofType == 'TPO' || roof.roofType == 'EPDM' || roof.roofType == 'Modified Bitumen';

  bool get _isMetal => roof.roofType == 'Metal';

  bool get _isShingles => roof.roofType == 'Shingles';

  Future<void> _takeCommercialPhoto({
    required String buildingName,
    required String roofName,
    required String photoLabel,
    required void Function(File file) onSaved,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (picked == null) return;

    final file = File(picked.path);
    final storedLabel = buildCommercialPhotoLabel(
      building: buildingName,
      roof: roofName,
      label: photoLabel,
    );

    setState(() {
      onSaved(file);
      widget.report.addPhoto(file, storedLabel);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo stored'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sync() {
    roof.roofLabel = _roofLabelController.text.trim().isEmpty
        ? null
        : _roofLabelController.text.trim();

    roof.pitch = _pitchController.text.trim().isEmpty
        ? null
        : _pitchController.text.trim();

    roof.deckTypeOtherSpecify = _deckOtherController.text.trim().isEmpty
        ? null
        : _deckOtherController.text.trim();

    roof.coverBoardOtherSpecify = _coverOtherController.text.trim().isEmpty
        ? null
        : _coverOtherController.text.trim();

    roof.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final building = widget.report.commercialBuildings[widget.buildingIndex];
    final buildingName = building.displayName(widget.buildingIndex);

    final roofName = (roof.roofLabel ?? '').trim().isEmpty
        ? 'Roof ${widget.roofIndex + 1}'
        : roof.roofLabel!.trim();

    final overviewLabel = 'Roof Overview Photo';

    final subtypes = subtypesForRoofType(roof.roofType);

    return Scaffold(
      appBar: AppBar(
        title: Text('$buildingName - $roofName'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _roofLabelController,
            decoration: const InputDecoration(
              labelText: 'Roof label (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _sync(),
          ),

            const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _takeCommercialPhoto(
              buildingName: buildingName,
              roofName: roofName,
              photoLabel: overviewLabel,
              onSaved: (f) => roof.overviewPhoto = f,
            ),
            child: const Text('Take overview photo'),
          ),
          TextButton(
            onPressed: () => _takeCommercialPhoto(
              buildingName: buildingName,
              roofName: roofName,
              photoLabel: '$overviewLabel additional photo',
              onSaved: (_) {},
            ),
            child: const Text('Add additional overview photo'),
          ),
          if (roof.overviewPhoto != null) ...[
            const SizedBox(height: 8),
            Image.file(roof.overviewPhoto!, height: 140, fit: BoxFit.cover),
          ],

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: roof.roofType,
            decoration: const InputDecoration(
              labelText: 'Roof cover type',
              border: OutlineInputBorder(),
            ),
            items: roofTypesAll
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) {
              setState(() {
                roof.roofType = val;
                roof.roofSubType = null;

                // Reset type-specific fields when switching.
                roof.metalStyle = null;
                roof.pitch = null;
                roof.facetCount = 1;

                roof.coreSamplePerformed = false;
                roof.coreSamplePhoto = null;
                roof.deckType = null;
                roof.deckTypeOtherSpecify = null;
                roof.insulationMaterial = null;
                roof.insulationThickness = null;
                roof.isTapered = false;
                roof.hasCoverBoard = false;
                roof.coverBoardType = null;
                roof.coverBoardThickness = null;
                roof.coverBoardOtherSpecify = null;
                roof.attachmentMethod = null;
                roof.noCoreSampleApproach = null;

                _pitchController.clear();
                _deckOtherController.clear();
                _coverOtherController.clear();
              });
            },
          ),
          if (subtypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.roofSubType,
              decoration: const InputDecoration(
                labelText: 'Subtype',
                border: OutlineInputBorder(),
              ),
              items: subtypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  roof.roofSubType = val;
                });
              },
            ),
          ],
          if (_isMetal) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.metalStyle,
              decoration: const InputDecoration(
                labelText: 'Metal style',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Flat', child: Text('Flat')),
                DropdownMenuItem(value: 'Gable', child: Text('Gable')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.metalStyle = val;
                  if (val == 'Gable') {
                    roof.facetCount = 2;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pitchController,
              decoration: const InputDecoration(
                labelText: 'Pitch (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _sync(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: roof.facetCount,
              decoration: const InputDecoration(
                labelText: 'How many facets?',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.facetCount = val ?? 1;
                });
              },
            ),
          ],
          if (_isShingles) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _pitchController,
              decoration: const InputDecoration(
                labelText: 'Pitch (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _sync(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: roof.facetCount,
              decoration: const InputDecoration(
                labelText: 'How many facets?',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.facetCount = val ?? 1;
                });
              },
            ),
          ],
          
          if (_isFlatSystem) ...[
            const SizedBox(height: 16),
            const Text(
              'Roof assembly (core sample / insulation / attachment)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              initialValue: roof.coreSamplePerformed,
              decoration: const InputDecoration(
                labelText: 'Core sample performed?',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: true, child: Text('Yes')),
                DropdownMenuItem(value: false, child: Text('No')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.coreSamplePerformed = val ?? false;
                  if (!roof.coreSamplePerformed) {
                    roof.coreSamplePhoto = null;
                  }
                });
              },
            ),
            if (roof.coreSamplePerformed) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _takeCommercialPhoto(
                  buildingName: buildingName,
                  roofName: roofName,
                  photoLabel: 'Core Sample Photo',
                  onSaved: (f) => roof.coreSamplePhoto = f,
                ),
                child: const Text('Take core sample photo'),
              ),
              TextButton(
                onPressed: () => _takeCommercialPhoto(
                  buildingName: buildingName,
                  roofName: roofName,
                  photoLabel: 'Core Sample Photo additional photo',
                  onSaved: (_) {},
                ),
                child: const Text('Add additional core sample photo'),
              ),
              if (roof.coreSamplePhoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.file(
                    roof.coreSamplePhoto!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
            ],   
                     
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.deckType,
              decoration: const InputDecoration(
                labelText: 'Deck type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Metal', child: Text('Metal')),
                DropdownMenuItem(value: 'Concrete', child: Text('Concrete')),
                DropdownMenuItem(value: 'Wood', child: Text('Wood')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.deckType = val;
                  if (val != 'Other') {
                    roof.deckTypeOtherSpecify = null;
                    _deckOtherController.clear();
                  }
                });
              },
            ),
            if (roof.deckType == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _deckOtherController,
                decoration: const InputDecoration(
                  labelText: 'Specify deck type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _sync(),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.insulationMaterial,
              decoration: const InputDecoration(
                labelText: 'Base insulation material',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ISO', child: Text('ISO')),
                DropdownMenuItem(value: 'EPS', child: Text('EPS')),
                DropdownMenuItem(value: 'XPS', child: Text('XPS')),
                DropdownMenuItem(value: 'Mineral Wool', child: Text('Mineral Wool')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.insulationMaterial = val;
                  roof.insulationThickness = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.insulationThickness,
              decoration: const InputDecoration(
                labelText: 'Base insulation thickness',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '1.0" (R-5.6)', child: Text('1.0" (R-5.6)')),
                DropdownMenuItem(value: '1.5" (R-8.5)', child: Text('1.5" (R-8.5)')),
                DropdownMenuItem(value: '2.0" (R-11.4)', child: Text('2.0" (R-11.4)')),
                DropdownMenuItem(value: '2.5" (R-14.4)', child: Text('2.5" (R-14.4)')),
                DropdownMenuItem(value: '3.0" (R-17.4)', child: Text('3.0" (R-17.4)')),
                DropdownMenuItem(value: '3.5" (R-20.5)', child: Text('3.5" (R-20.5)')),
                DropdownMenuItem(value: '4.0" (R-23.6)', child: Text('4.0" (R-23.6)')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.insulationThickness = val;
                });
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Is tapered?'),
              value: roof.isTapered,
              onChanged: (val) {
                setState(() {
                  roof.isTapered = val ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Has cover board?'),
              value: roof.hasCoverBoard,
              onChanged: (val) {
                setState(() {
                  roof.hasCoverBoard = val ?? false;
                  if (!roof.hasCoverBoard) {
                    roof.coverBoardType = null;
                    roof.coverBoardThickness = null;
                    roof.coverBoardOtherSpecify = null;
                    _coverOtherController.clear();
                  }
                });
              },
            ),
            if (roof.hasCoverBoard) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roof.coverBoardType,
                decoration: const InputDecoration(
                  labelText: 'Cover board type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'DensDeck', child: Text('DensDeck')),
                  DropdownMenuItem(value: 'HD ISO', child: Text('HD ISO')),
                  DropdownMenuItem(value: 'Wood Fiber', child: Text('Wood Fiber')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  setState(() {
                    roof.coverBoardType = val;
                    if (val != 'Other') {
                      roof.coverBoardOtherSpecify = null;
                      _coverOtherController.clear();
                    }
                  });
                },
              ),
              if (roof.coverBoardType == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _coverOtherController,
                  decoration: const InputDecoration(
                    labelText: 'Specify cover board type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _sync(),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roof.coverBoardThickness,
                decoration: const InputDecoration(
                  labelText: 'Cover board thickness',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '1/4"', child: Text('1/4"')),
                  DropdownMenuItem(value: '1/2"', child: Text('1/2"')),
                ],
                onChanged: (val) {
                  setState(() {
                    roof.coverBoardThickness = val;
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roof.attachmentMethod,
              decoration: const InputDecoration(
                labelText: 'Attachment method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Mechanical', child: Text('Mechanical (fasteners)')),
                DropdownMenuItem(value: 'Adhered', child: Text('Adhered')),
                DropdownMenuItem(value: 'Ballasted', child: Text('Ballasted')),
              ],
              onChanged: (val) {
                setState(() {
                  roof.attachmentMethod = val;
                });
              },
            ),
            if (!roof.coreSamplePerformed) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roof.noCoreSampleApproach,
                decoration: const InputDecoration(
                  labelText: 'If no core sample, estimate approach',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'EnergyCode', child: Text('Estimate per energy code / climate standard')),
                  DropdownMenuItem(value: 'BidItem', child: Text('Leave as Bid Item (0)')),
                ],
                onChanged: (val) {
                  setState(() {
                    roof.noCoreSampleApproach = val;
                  });
                },
              ),
            ],
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Roof notes (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _sync();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
