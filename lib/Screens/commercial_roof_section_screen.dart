import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../catalogs/roof_catalog.dart';
import '../inspection_report_model.dart';
import '../utils/photo_labels.dart';
import 'commercial_building_details_screen.dart';

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
  final _deckThicknessGaugeController = TextEditingController();
  final _deckPartialSqftController = TextEditingController();

  final _coverOtherController = TextEditingController();
  final _notesController = TextEditingController();

  bool _showFinishActions = false;

  Future<void> _showSubmissionOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submission Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Commercial submission options are not implemented yet.'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final building = widget.report.commercialBuildings[widget.buildingIndex];
    roof = building.roofs[widget.roofIndex];

    _roofLabelController.text = roof.roofLabel ?? '';
    _pitchController.text = roof.pitch ?? '';
    _deckOtherController.text = roof.deckTypeOtherSpecify ?? '';
    _deckThicknessGaugeController.text = roof.deckThicknessGauge ?? '';
    _deckPartialSqftController.text = roof.deckPartialReplacementSqft ?? '';

    _coverOtherController.text = roof.coverBoardOtherSpecify ?? '';
    _notesController.text = roof.notes ?? '';
  }

  @override
  void dispose() {
    _roofLabelController.dispose();
    _pitchController.dispose();
    _deckOtherController.dispose();
    _deckThicknessGaugeController.dispose();
    _deckPartialSqftController.dispose();
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

    roof.deckThicknessGauge = _deckThicknessGaugeController.text.trim().isEmpty
        ? null
        : _deckThicknessGaugeController.text.trim();

    roof.deckPartialReplacementSqft =
        _deckPartialSqftController.text.trim().isEmpty
            ? null
            : _deckPartialSqftController.text.trim();

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
                roof.insulationKnown = null;

                roof.deckChangeRequired = false;
                roof.deckFullReplacementRequired = false;
                roof.deckPartialReplacementSqft = null;
                roof.deckType = null;
                roof.deckTypeOtherSpecify = null;
                roof.deckThicknessGauge = null;

                roof.insulationMaterial = null;
                roof.insulationThickness = null;
                roof.isTapered = false;
                roof.hasCoverBoard = false;
                roof.coverBoardType = null;
                roof.coverBoardThickness = null;
                roof.coverBoardOtherSpecify = null;

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
              'Roof assembly',
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
                  if (roof.coreSamplePerformed) {
                    roof.insulationKnown = true;
                    roof.noCoreSampleApproach = null;
                  } else {
                    roof.coreSamplePhoto = null;
                    roof.insulationKnown = null;
                  }
                });
              },
            ),
            if (!roof.coreSamplePerformed) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                initialValue: roof.insulationKnown,
                decoration: const InputDecoration(
                  labelText: 'Is the sublayer system known?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Yes')),
                  DropdownMenuItem(value: false, child: Text('No')),
                ],
                onChanged: (val) {
                  setState(() {
                    roof.insulationKnown = val;
                    if (roof.insulationKnown == false) {
                      roof.insulationMaterial = null;
                      roof.insulationThickness = null;
                      roof.isTapered = false;
                      roof.hasCoverBoard = false;
                      roof.coverBoardType = null;
                      roof.coverBoardOtherSpecify = null;
                      roof.coverBoardThickness = null;
                    } else {
                      roof.noCoreSampleApproach = null;
                    }
                  });
                },
              ),
            ],
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

            if (roof.coreSamplePerformed || roof.insulationKnown == true) ...[
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
            ],

            if (roof.coreSamplePerformed == false && roof.insulationKnown == false) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roof.noCoreSampleApproach,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sublayer estimating approach',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'EnergyCode',
                    child: Text(
                      'Estimate per energy code / climate zone',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'BidItem',
                    child: Text('Leave as Bid Item (0)'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    roof.noCoreSampleApproach = val;
                  });
                },
              ),
            ],

            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Deck required to be changed?'),
              value: roof.deckChangeRequired,
              onChanged: (val) {
                setState(() {
                  roof.deckChangeRequired = val ?? false;
                  if (!roof.deckChangeRequired) {
                    roof.deckFullReplacementRequired = false;
                    roof.deckPartialReplacementSqft = null;
                    _deckPartialSqftController.clear();
                    roof.deckType = null;
                    roof.deckTypeOtherSpecify = null;
                    _deckOtherController.clear();
                    roof.deckThicknessGauge = null;
                    _deckThicknessGaugeController.clear();
                  }
                });
              },
            ),
            if (roof.deckChangeRequired) ...[
              CheckboxListTile(
                title: const Text('Deck full replacement required?'),
                value: roof.deckFullReplacementRequired,
                onChanged: (val) {
                  setState(() {
                    roof.deckFullReplacementRequired = val ?? false;
                    if (roof.deckFullReplacementRequired) {
                      roof.deckPartialReplacementSqft = null;
                      _deckPartialSqftController.clear();
                    }
                  });
                },
              ),
              if (!roof.deckFullReplacementRequired)
                TextField(
                  controller: _deckPartialSqftController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'How many SF of decking require replacement?',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _sync(),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: roof.deckType,
                decoration: const InputDecoration(
                  labelText: 'Deck type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Metal', child: Text('Metal')),
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
                    if (val != 'Metal' && val != 'Wood') {
                      roof.deckThicknessGauge = null;
                      _deckThicknessGaugeController.clear();
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
              if (roof.deckType == 'Metal' || roof.deckType == 'Wood') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _deckThicknessGaugeController,
                  decoration: const InputDecoration(
                    labelText: 'Deck thickness / gauge',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _sync(),
                ),
              ],
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _takeCommercialPhoto(
                  buildingName: buildingName,
                  roofName: roofName,
                  photoLabel: 'Additional Photo',
                  onSaved: (_) {},
                );
              },
              child: const Text('Take additional images'),
            ),
          ),
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
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (context) {
                final buildings = widget.report.commercialBuildings;
                final isLastBuilding = widget.buildingIndex >= buildings.length - 1;
                final building = buildings[widget.buildingIndex];
                final isLastRoof = widget.roofIndex >= building.roofs.length - 1;
                final isFinalStep = isLastBuilding && isLastRoof;

                if (isFinalStep && _showFinishActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final images = await _picker.pickMultiImage(
                              maxWidth: 1024,
                              imageQuality: 80,
                            );

                            if (images.isEmpty) return;

                            for (final x in images) {
                              widget.report.addPhoto(
                                File(x.path),
                                buildCommercialPhotoLabel(
                                  building: buildingName,
                                  roof: roofName,
                                  label: 'User Image',
                                ),
                              );
                            }

                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Photos added')),
                            );
                          },
                          child: const Text('Add Images from Gallery'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (widget.report.inspectElevations) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Elevations flow not implemented yet.'),
                                ),
                              );
                              return;
                            }

                            await _showSubmissionOptions();
                          },
                          child: const Text('Submit Inspection'),
                        ),
                      ),
                    ],
                  );
                }

                return ElevatedButton(
                  onPressed: () async {
                    _sync();

                    if (isFinalStep) {
                      setState(() {
                        _showFinishActions = true;
                      });
                      return;
                    }

                    final nextRoofIndex = widget.roofIndex + 1;
                    if (nextRoofIndex < building.roofs.length) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => CommercialRoofSectionScreen(
                            plan: widget.plan,
                            report: widget.report,
                            buildingIndex: widget.buildingIndex,
                            roofIndex: nextRoofIndex,
                          ),
                        ),
                      );
                      return;
                    }

                    final nextBuildingIndex = widget.buildingIndex + 1;
                    if (nextBuildingIndex < buildings.length) {
                      final nextBuilding = buildings[nextBuildingIndex];
                      if (nextBuilding.roofs.isEmpty) {
                        nextBuilding.roofs.add(
                          CommercialRoofSectionData()..roofLabel = 'Main Roof',
                        );
                      }

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => CommercialBuildingDetailScreen(
                            plan: widget.plan,
                            report: widget.report,
                            buildingIndex: nextBuildingIndex,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isFinalStep ? 'Finish Inspection' : 'Save & Continue'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
