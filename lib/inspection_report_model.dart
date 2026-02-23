import 'dart:io';

class InspectionReport {
  // CLIENT & CLAIM
  String clientName = '';
  String clientPhone = '';
  String email = '';
  String address = ''; // Street Address (calle + número)
  String city = '';
  String state = '';
  String zip = '';
  String claimNumber = '';
  String policyNumber = '';
  String dateOfLoss = '';
  String dateInspected = '';
  String insuranceCompany = ''; // aseguradora
  String typeOfLoss = '';
  String causeOfLoss = '';
  bool isResidential = true;

  // INSPECTOR
  String inspectorCompany = '';  // empresa que inspecciona
  String inspectorName = '';
  String inspectorPhone = '';
  String inspectorEmail = '';

  // INSPECTION SCOPE
  bool inspectRoof = true;
  bool inspectElevations = false;
  bool inspectInterior = false;
  String interiorScope = ''; // 'Mitigation', 'Restoration', 'Both' o ''

  // ROOF FORM
  String? roofCoverType;
  String? roofSubType;
  int? estimatedAge;
  int? numLayers;

  bool hasDripEdge = false;
  String? dripEdgeType;

  bool hasShed = false;
  bool hasDetachedStructure = false;

  File? frontElevationPhoto;
  File? dripEdgePhoto;

  bool hasGlobalRidgeVent = false;
  String? globalRidgeVentType;
  File? globalRidgeVentPhoto;

    // Roof replacement scope
  bool fullRoofReplacementRequired = false;
  String? partialReplacementSqft; // texto tal cual, ej: "250"

  // Sheathing replacement scope
  bool sheathingRequiredToBeChanged = false;
  bool sheathingFullReplacementRequired = false;
  String? sheathingPartialReplacementSqft; // ej: "120"
  String? sheathingType;  // 'OSB' o 'CDX'
  String? sheathingSize;  // '1/2"' o '5/8"'
  
  // REPORT CONTENT
  List<PhotoItem> photoReportItems = [];
  List<FacetData> facets = [];

  void addPhoto(File file, String label) {
    photoReportItems.add(PhotoItem(file: file, label: label));
  }
}


class PhotoItem {
  final File file;
  final String label;
  PhotoItem({required this.file, required this.label});
}

class FlashingData {
  String type;             // Step flashing, Ridge flashing, etc.
  String? material;        // Metal, Copper
  String? size;            // 14", 20", Small, Average, Large, Standard, ...
  String? finish;          // Mill finish, Color finish
  String? grade;           // Standard, High grade
  String? otherSpecify;    // Only when type == "Other"
  bool shouldBeChanged;

  FlashingData({
    required this.type,
    this.material,
    this.size,
    this.finish,
    this.grade,
    this.otherSpecify,
    this.shouldBeChanged = false,
  });
}

class VentData {
  String type;          // ej: "Turtle vent Metal", "Pipe jack", "Other"
  String? count;        // texto tal como se ingresa, ej: "3"
  bool shouldBeChanged;
  bool includeSplitBoot;
  bool includeLead;
  String? otherSpecify; // texto libre cuando type == "Other"

  VentData({
    required this.type,
    this.count,
    this.shouldBeChanged = false,
    this.includeSplitBoot = false,
    this.includeLead = false,
    this.otherSpecify,
  });
}

  class FacetData {
    String name;
    String orientation;
    String? pitch;

    bool starterRowInstalled;
    bool starterEaveInstalled;
    bool starterRakeInstalled;

    bool atrPerformed;
    String? atrResult;

    bool hasValleyMetal;
    String? valleyMetalType;
    List<FlashingData> flashings;
    List<VentData> vents;

    List<OtherElementData> otherElements;

    String? comment;
    
    FacetData({
      required this.name,
      required this.orientation,
      this.pitch,
      this.starterRowInstalled = false,
      this.starterEaveInstalled = false,
      this.starterRakeInstalled = false,
      this.atrPerformed = false,
      this.atrResult,
      this.hasValleyMetal = false,
      this.valleyMetalType,
      this.flashings = const [],
      this.vents = const [],
      this.otherElements = const [], 
      this.comment,
    });
    }
    class OtherElementData {
  String type;               // Snow guard/stop, Skylight, etc.
  String? count;             // texto numérico
  bool shouldBeChanged;
  bool detachAndResetOnly;   // uno u otro, no ambos
  String? otherSpecify;      // solo cuando type == "Other"

  OtherElementData({
    required this.type,
    this.count,
    this.shouldBeChanged = false,
    this.detachAndResetOnly = false,
    this.otherSpecify,
  });
}