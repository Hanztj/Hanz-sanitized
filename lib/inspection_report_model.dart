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
  bool iceAndWaterBarrierInstalled = false;
  File? iceAndWaterBarrierPhoto;

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

  bool starterRowInstalled = false;
  bool starterEaveInstalled = false;
  bool starterRakeInstalled = false;

  File? starterEavePhoto;
  File? starterRakePhoto;

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

   // COMMERCIAL
  List<CommercialBuildingData> commercialBuildings = [];

  void addPhoto(File file, String label) {
    photoReportItems.add(PhotoItem(file: file, label: label));
  }
}

class PhotoItem {
  final File file;
  final String label;
  PhotoItem({required this.file, required this.label});
}

class CommercialBuildingData {
  String? name;
  bool differentAddress = false;
  String? streetAddress;

  bool hasMultipleRoofTypes = false;
  List<CommercialRoofSectionData> roofs = [];

  String? notes;

  CommercialBuildingData();

  String displayName(int index) {
    final n = (name ?? '').trim();
    return n.isEmpty ? 'Building ${index + 1}' : n;
  }
}

class CommercialRoofSectionData {
  String? roofLabel;
  String? roofType;
  String? roofSubType;

  // Shingles/Metal simplification
  String? pitch;
  int facetCount = 1;

  // Metal
  String? metalStyle; // Flat / Gable / Other

  // Flat systems
  bool coreSamplePerformed = false;
  File? coreSamplePhoto;

  String? deckType; // Metal/Concrete/Wood/Other
  String? deckTypeOtherSpecify;

  String? insulationMaterial; // ISO/EPS/XPS/Mineral Wool
  String? insulationThickness;
  bool isTapered = false;

  bool hasCoverBoard = false;
  String? coverBoardType; // DensDeck/HD ISO/Wood Fiber/Other
  String? coverBoardOtherSpecify;
  String? coverBoardThickness; // 1/4" / 1/2"

  String? attachmentMethod; // Mechanical / Adhered / Ballasted

  // Only when coreSamplePerformed == false
  String? noCoreSampleApproach; // 'EnergyCode' or 'BidItem'

  File? overviewPhoto;

  List<AccessoryItemData> accessories = [];
  List<HvacUnitData> hvacUnits = [];

  String? notes;
}

class AccessoryItemData {
  String? type;
  String? otherSpecify;

  String? count;
  bool shouldBeChanged = false;
  bool detachAndResetOnly = false;

  File? photo;
  List<File> extraPhotos = [];

  String? notes;
}

class HvacUnitData {
  String? type; // AC Unit / RTU / Other
  String? otherSpecify;

  String action = 'No action required';

  bool capacityKnown = false;
  String? capacityText;

  bool nameplatePhotoCaptured = false;
  File? nameplatePhoto;
  List<File> extraPhotos = [];

  String? notes;
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

  // Ridge Vent (POR FACETA)
  bool hasRidgeVent;
  String? ridgeVentType;
  File? ridgeVentPhoto;

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

    this.hasRidgeVent = false,
    this.ridgeVentType,
    this.ridgeVentPhoto,

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
