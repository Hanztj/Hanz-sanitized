import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:claimscope_clean/services/stripe_service.dart';
import 'package:claimscope_clean/Services/pdf_service.dart';
//firebase imports here
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:claimscope_clean/Services/email_service.dart';
import 'package:claimscope_clean/inspection_report_model.dart';
//ignore unused imports for now, will be used in the future when implementing the functions
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:claimscope_clean/screens/my_reports_screen.dart';
enum FacetOrientation {
  north,
  south,
  east,
  west, 
  none, // Para cuando no se ha seleccionado ninguna
}
class RoofInspectionForm extends StatefulWidget {
  
  final String plan; // Cambiado de bool isSubscribed
  final InspectionReport report;
  final bool isCommercial; // Para diferenciar residencial/comercial en cálculos y opciones


  const RoofInspectionForm({super.key, required this.plan, required this.report, required this.isCommercial});

  @override
  State<RoofInspectionForm> createState() => _RoofInspectionFormState();
}

class _RoofInspectionFormState extends State<RoofInspectionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
                    
 // Añadir dentro de class _RoofInspectionFormState extends State<RoofInspectionForm> {

 void _showSubmissionOptions(File techPdf, File photoPdf) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Send Inspection Report'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              // Opción 1: Enviar a su propio correo (Basic & Premium) – sin cobro HF
              
               // Opciones HF Estimates (Basic & Premium) – aquí SÍ habrá cobro
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Send to HF Estimates by email'),
                subtitle: const Text(
                  'This will create a paid estimate Order',
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _confirmRushAndSendToHfByEmail(techPdf, photoPdf);
                },
              ),
              const Divider(),
              if (widget.plan != 'premium')
                ListTile(
                  leading: const Icon(Icons.send_to_mobile),
                  title: const Text(
                    'Send as Assignment via XactAnalysis to (HF Estimates)',
                  ),
                  subtitle: const Text(
                    'Create a paid assignment to hfestimates@hfestimates.com via Xactimate API.',
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _confirmRushAndSendToHfViaXactimate(
                      techPdf,
                      photoPdf,
                    );
                  },
                ),

              
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('1) Send to my email'),
                subtitle: const Text(
                  'Receive the PDF report(s) in your registered email.',
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _sendReportViaEmail(techPdf, photoPdf);
                },
              ),
              const Divider(),

              // Opciones adicionales para Premium (plan alto)
              if (widget.plan == 'premium') ...[
                // Enviar a otros correos – sin cobro HF
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('2) Send to another email'),
                  subtitle: const Text(
                    'Send the reports to any email address.',
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _sendReportToCustomEmail(techPdf, photoPdf);
                  },
                ),

                const Divider(),

                              if (widget.plan == 'premium')
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text(
                    'Send as Assignment to my XactNet account',
                  ),
                  subtitle: const Text(
                    'Assign directly to your own XactNet account via Xactimate API.',
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _sendToUserXactNetAccount(techPdf, photoPdf);
                  },
                ),
                  
                  const Divider(),

                  if (widget.plan == 'premium')
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text(
                    'Store in Cloud',
                  ),
                  subtitle: const Text(
                    'Save a copy of the report in your account (Cloud storage).',
                  ),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    await _storeReportInCloud(techPdf, photoPdf);
                  },
                ),
              ] else
                Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                 onPressed: () {
                 // No necesitamos await aquí; solo disparamos el checkout de Premium
                 StripeService.launchCheckout('premium');
               },
                child: Text(
                   'Upgrade to Premium to enable cloud storage,\nadditional recipients and Xactimate integration.',
                   textAlign: TextAlign.center,
                   style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  ),
                  ),
             
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
 }
                 
              Widget _buildFlashingSubfields(Map<String, dynamic> data) {
  final String? type = data['type'];

  if (type == null) return const SizedBox.shrink();

  // Step flashing, Ridge flashing -> Metal/Copper
  if (type == 'Step flashing' || type == 'Ridge flashing') {
    return buildDropdown(
      'Material',
      ['Metal', 'Copper'],
      data['material'],
      (val) => setState(() => data['material'] = val),
    );
  }

  // Counter/Apron flashing -> Standard/Copper
  if (type == 'Counter/Apron flashing') {
    return buildDropdown(
      'Material',
      ['Standard', 'Copper'],
      data['material'],
      (val) => setState(() => data['material'] = val),
    );
  }

  // Wide flashing -> 14"/20" + Copper? (lo mapeamos como size y material)
  if (type == 'Wide flashing') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDropdown(
          'Size',
          ['14"', '20"'],
          data['size'],
          (val) => setState(() => data['size'] = val),
        ),
        buildDropdown(
          'Material',
          ['Standard', 'Copper'],
          data['material'],
          (val) => setState(() => data['material'] = val),
        ),
      ],
    );
  }
   // Sidewall/Endwall flashing -> mill finish / color finish
  if (type == 'Sidewall/Endwall flashing') {
    return buildDropdown(
      'Finish',
      ['Mill finish', 'Color finish'],
      data['finish'],
      (val) => setState(() => data['finish'] = val),
    );
  }
  // L flashing -> Galvanized / Color finish
 if (type == 'L flashing') {
  return buildDropdown(
    'Material / Finish',
    ['Galvanized', 'Color finish'],
    data['material'],
    (val) => setState(() => data['material'] = val),
  );
 }
  // Chimney flashing -> small/average/large + Metal/Copper
  if (type == 'Chimney flashing') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDropdown(
          'Size',
          ['Small', 'Average', 'Large'],
          data['size'],
          (val) => setState(() => data['size'] = val),
        ),
        buildDropdown(
          'Material',
          ['Metal', 'Copper'],
          data['material'],
          (val) => setState(() => data['material'] = val),
        ),
      ],
    );
  }
  // Roof window step flashing kit -> standard/large
  if (type == 'Roof window step flashing kit') {
    return buildDropdown(
      'Size',
      ['Standard', 'Large'],
      data['size'],
      (val) => setState(() => data['size'] = val),
    );
  }
  // Skylight flashing kit (dome) -> average/large + Standard/high grade
  if (type == 'Skylight flashing kit (dome)') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDropdown(
          'Size',
          ['Average', 'Large'],
          data['size'],
          (val) => setState(() => data['size'] = val),
        ),
        buildDropdown(
          'Grade',
          ['Standard', 'High grade'],
          data['grade'],
          (val) => setState(() => data['grade'] = val),
        ),
      ],
    );
  }
  return const SizedBox.shrink();
 }     
 // Paso adicional: preguntar por Rush Order ANTES de calcular precio / cobrar / enviar
 void _confirmRushAndSendToHfByEmail(File techPdf, File photoPdf) {
  bool rush = false;

  showDialog(
    context: context,
    builder: (rushDialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rush Order? (+\$15)'),
            content: CheckboxListTile(
              title: const Text('Is this a rush order? (+\$15)'),
              value: rush,
              onChanged: (val) {
                setState(() {
                  rush = val ?? false;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(rushDialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(rushDialogContext).pop();
   
                  _sendToHfByEmail(techPdf, photoPdf, rushOrder: rush);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );
 } 

 void _confirmRushAndSendToHfViaXactimate(File techPdf, File photoPdf) {
  bool rush = false;

  showDialog(
    context: context,
    builder: (rushDialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rush Order? (+\$15)'),
            content: CheckboxListTile(
              title: const Text('Is this a rush order? (+\$15)'),
              value: rush,
              onChanged: (val) {
                setState(() {
                  rush = val ?? false;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(rushDialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(rushDialogContext).pop();
                  // Igual que antes, pero vía Xactimate:
                  // Precio base + shed + estructura + rush + descuento plan
                  // Luego backend/Stripe y después assignment a hfestimates@hfestimates.com
                  _sendToHfViaXactimate(techPdf, photoPdf,
                      rushOrder: rush);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );
 }
 // Function helper email 
  bool _isProbablyValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  if (email.contains(' ')) return false;

  final at = email.indexOf('@');
  if (at <= 0) return false; // no puede empezar con @
  if (at != email.lastIndexOf('@')) return false; // solo un @

  final dot = email.lastIndexOf('.');
  if (dot <= at + 1) return false; // debe haber un . después del @
  if (dot == email.length - 1) return false; // no termina con .

  return true;
}
 // Solo Premium+Extra : preguntar si quiere almacenar en la nube (sin cobro HF)

Future<bool> _askStoreReportInCloud() async {
  if (widget.plan != 'premium') return false;

  final navigator = Navigator.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Store report in Cloud?'),
      content: const Text(
        'Do you want to store this inspection report in your account (Cloud)?',
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => navigator.pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );

  return result ?? false;
}
Future<void> _storeReportInCloud(File techPdf, File photoPdf) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('User not authenticated.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 16),
          Expanded(child: Text('Storing report in Cloud...')),
        ],
      ),
    ),
  );

  try {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final reportRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('inspectionReports')
        .doc(); // doc().id generado

    final reportId = reportRef.id;

    final techPath = 'user_reports/${user.uid}/$reportId/Tech_Report.pdf';
    final photoPath = 'user_reports/${user.uid}/$reportId/Photo_Report.pdf';

    await storage.ref(techPath).putFile(techPdf);
    await storage.ref(photoPath).putFile(photoPdf);

    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 60)),
    );

    await reportRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'claimNumber': widget.report.claimNumber,
      'clientName': widget.report.clientName,
      'techPath': techPath,
      'photoPath': photoPath,
    });

    if (!mounted) return;
    navigator.pop();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Report stored in Cloud.'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    navigator.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Error storing report: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

 Future<void> _sendReportViaEmail(File techPdf, File photoPdf, {String? extraEmail}) async {
                // Aquí se llamara un servicio backend
                               final messenger = ScaffoldMessenger.of(context);
                               final user = FirebaseAuth.instance.currentUser;
                               if (user == null || user.email == null || user.email!.isEmpty) {
                                     messenger.showSnackBar(
                                const SnackBar(content: Text('User not authenticated')),
                                );
                               return;
                                }
                                    
                                    final toEmails = <String>[user.email!];
                                if (widget.plan == 'premium' && extraEmail != null && extraEmail.trim().isNotEmpty) {
                                 toEmails.add(extraEmail.trim());
                               }     
                                    
                                   messenger.showSnackBar(
                               const SnackBar(content: Text('Sending email...')),
                                );
                                  try {
                               await EmailService.sendEmailWithReports(
                               toEmails: toEmails,
                               techPdf: techPdf,
                               photoPdf: photoPdf,
                                 );

                               if (!mounted) return;

                              messenger.showSnackBar(
                               const SnackBar(content: Text('Email sent successfully')),
                              );
                               final shouldStore = await _askStoreReportInCloud();
                               if (shouldStore) {
                               await _storeReportInCloud(techPdf, photoPdf);
                              }
                               
                               } catch (e) {
                              if (!mounted) return;

                               messenger.showSnackBar(
                               SnackBar(content: Text('Error sending email: $e')),
                             );
                              }
       }
   // Solo Premium: enviar a otros correos (sin cobro HF)
void _sendReportToCustomEmail(File techPdf, File photoPdf) {
  final extraEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Send to another email'),
      content: TextField(
        controller: extraEmailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Recipient email',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final extraEmail = extraEmailController.text.trim();
            Navigator.pop(ctx);
            if (!_isProbablyValidEmail(extraEmail)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid email.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            await _sendReportViaEmail(techPdf, photoPdf, extraEmail: extraEmail);
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
   // Solo Premium: almacenar + email (sin cobro HF)
   // HF Estimates por email (Basic & Premium) – aquí sí habrá cobro HF
 //--Helper price calculation function
        double _calculateHfEmailPrice({required bool rushOrder}) {
    
                          const double basePrice = 70.0;        // precio base por roof estimate
                          const double shedAddon = 10.0;        // extra si hay shed
                          const double structureAddon = 15.0;   // extra si hay estructura grande
                          const double rushFee = 15.0;          // rush order
                          const double commercialExtra = 20.0;  // extra para comercial
  
                                double total = basePrice;
  
                                if (hasShed) {total += shedAddon;
                                }
                                if (hasDetachedStructure) {total += structureAddon;
                                }
                                if (widget.isCommercial) {total += commercialExtra;
                                }
                                if (rushOrder) {total += rushFee;
                                }
  
                          // Descuento 10% para el plan básico, 15% para el premium (aplicado al total después de sumar addons y rush)
                            if (widget.plan == 'basic') total *= 0.90;   // 10%
                            if (widget.plan == 'premium') total *= 0.85; // 15% total
  
                              return total;
                              }

   Future<void> _sendToHfByEmail(File techPdf, File photoPdf,
        {required bool rushOrder}) async{  
            final shouldStore = await _askStoreReportInCloud();
  if (!mounted) return;

  if (shouldStore) {
    await _storeReportInCloud(techPdf, photoPdf);
    if (!mounted) return;
  }

             final messenger = ScaffoldMessenger.of(context);
             final total = _calculateHfEmailPrice(rushOrder: rushOrder);
            
  showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => const AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Expanded(child: Text('Please wait… preparing checkout')),
      ],
    ),
  ),
);
        try{    
  messenger.showSnackBar(
    SnackBar(content: Text('Preparing HF order... Total: \$${total.toStringAsFixed(2)}',
      ),
      duration: const Duration(seconds: 3),
    ),
  );
  
       //Upload PDFs to cloud storage and get URLs (placeholder logic, implement with Firebase Storage or similar)
  final storage =  FirebaseStorage.instance;
  final timeStamp = DateTime.now().millisecondsSinceEpoch;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final techUploadTask = await storage.ref('temp_reports/$uid/hf_orders/$timeStamp/tech.pdf').putFile(techPdf);
  final photoUploadTask = await storage.ref('temp_reports/$uid/hf_orders/$timeStamp/photos.pdf').putFile(photoPdf);

  final techUrl = await techUploadTask.ref.getDownloadURL();
  final photoUrl = await photoUploadTask.ref.getDownloadURL();

    // Llamar a backend para crear orden en HF Estimates (puede ser una Cloud Function que luego llama a la API de Xactimate)
  final callable = FirebaseFunctions.instance.httpsCallable('createHfEstimatesCheckoutSession');

       final result = await callable.call({
    'techPdfUrl': techUrl,
    'photoPdfUrl': photoUrl,
    'rushOrder': rushOrder,
    'isCommercial': widget.isCommercial,
    'hasShed': hasShed,
    'hasDetachedStructure': hasDetachedStructure,
    'plan': widget.plan, // 'basic' / 'premium'

    'userEmail': FirebaseAuth.instance.currentUser?.email,
    'clientName': widget.report.clientName,
    'claimNumber': widget.report.claimNumber,
    'address': '${widget.report.address}, ${widget.report.city}, ${widget.report.state} ${widget.report.zip}',
    'dateInspected': widget.report.dateInspected,
    'successUrl': 'claimscope://success',
    'cancelUrl': 'claimscope://cancel',
  });
     final sessionUrl = result.data['url'] as String?;
     if (sessionUrl == null) {
    throw Exception("La función no devolvió la URL de Stripe.");
  }

  // Abrir la URL de Stripe Checkout
        final url = Uri.parse(sessionUrl);
        final success= await launchUrl(url, mode: LaunchMode.externalApplication);
          if (!success) {
            throw Exception("No se pudo abrir Stripe Checkout.");
          }
               } catch (e) {
      debugPrint('HF Xactimate failed: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color.fromARGB(255, 244, 54, 54),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } finally {if (mounted) Navigator.of(context, rootNavigator: true).pop();
   }
        }

// --- ENVÍO VÍA XACTIMATE (CON CATCH PARA DEPURAR) ---
  Future<void> _sendToHfViaXactimate(File techPdf, File photoPdf, {required bool rushOrder}) async {
        final shouldStore = await _askStoreReportInCloud();
  if (!mounted) return;

  if (shouldStore) {
    await _storeReportInCloud(techPdf, photoPdf);
    if (!mounted) return;
  }


    final messenger = ScaffoldMessenger.of(context);
    final total = _calculateHfEmailPrice(rushOrder: rushOrder);

    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => const AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Expanded(child: Text('Please wait… preparing checkout')),
      ],
    ),
  ),
);

    try {
      messenger.showSnackBar(
        SnackBar(content: Text('Preparing HF Xactimate assignment... Total: \$${total.toStringAsFixed(2)}')),
      );

      final storage = FirebaseStorage.instance;
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final techUploadTask = await storage
          .ref('temp_reports/$uid/hf_orders_xactimate/$timeStamp/tech.pdf')
          .putFile(techPdf);

      final photoUploadTask = await storage
          .ref('temp_reports/$uid/hf_orders_xactimate/$timeStamp/photos.pdf')
          .putFile(photoPdf);

      final techUrl = await techUploadTask.ref.getDownloadURL();
      final photoUrl = await photoUploadTask.ref.getDownloadURL();

      final callable = FirebaseFunctions.instance
          .httpsCallable('createHfEstimatesXactimateCheckoutSession');

      final result = await callable.call({
        'techPdfUrl': techUrl,
        'photoPdfUrl': photoUrl,
        'rushOrder': rushOrder,
        'isCommercial': widget.isCommercial,
        'hasShed': hasShed,
        'hasDetachedStructure': hasDetachedStructure,
        'plan': widget.plan,
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'clientName': widget.report.clientName,
        'claimNumber': widget.report.claimNumber,
        'address': '${widget.report.address}, ${widget.report.city}, ${widget.report.state} ${widget.report.zip}',
        'dateInspected': widget.report.dateInspected,
        'successUrl': 'claimscope://success',
        'cancelUrl': 'claimscope://cancel',
      });

      debugPrint('createHfEstimatesXactimateCheckoutSession result: ${result.data}');

      final sessionUrl = result.data['url'] as String?;
      if (sessionUrl == null) throw Exception("Cloud Function did not return a checkout url.");

      final url = Uri.parse(sessionUrl);
      final success = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!success) throw Exception("Could not open Stripe Checkout.");

     } catch (e) {
      debugPrint('HF Xactimate failed: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color.fromARGB(255, 244, 54, 54),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } finally {if (mounted) Navigator.of(context, rootNavigator: true).pop();
   }
  } 

    void _sendToUserXactNetAccount(File techPdf, File photoPdf) {
     // Llamar a backend/Xactimate API con XactNet del usuario
    }
       Future<void> _takeExtraPhotoForLabel(String label) async {
  await _takePhoto(
    label,
    isFacetPhoto: false,
  );
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Photo stored'),
      duration: Duration(seconds: 2),
    ),
  );
  }
         
   // Input variables for main form
    // Input variables for main form
   String? roofCoverType;
   String? roofSubType;
   String? selectedGauge;
   int? estimatedAge;
   int? numLayers;
 
   bool hasDripEdge = false;
   String? dripEdgeType;
   File? dripEdgePhoto;

   File? frontElevationPhoto;

   bool hasGlobalRidgeVent = false;
   String? globalRidgeVentType;
   File? globalRidgeVentPhoto;

   bool gravelBallastPresent = false;

   bool hasShed = false;
   bool hasDetachedStructure = false;

     bool fullRoofReplacementRequired = false;
  String? partialReplacementSqft;

  bool sheathingRequiredToBeChanged = false;
  bool sheathingFullReplacementRequired = false;
  String? sheathingPartialReplacementSqft;
  String? sheathingType;
  String? sheathingSize;

  final TextEditingController _partialReplacementSqftController =
      TextEditingController();
  final TextEditingController _sheathingPartialSqftController =
      TextEditingController();

   // Fotos para thumbnails al final (además de widget.report.photoReportItems)
   final List<File> photoReportImages = [];

   // Si ya no usas inspectionData para el PDF, puedes eliminarlo o dejarlo
   // solo para la parte visual. Como en tu thumbnail lo usas, mantenlo:
   final List<Map<String, String>> inspectionData = [];
    // --- VARIABLES DE INTERFAZ (Sincronizadas con widget.report) ---
   final TextEditingController otherRoofCoverTypeController = TextEditingController();
   final TextEditingController otherMetalSubTypeController = TextEditingController();
   final TextEditingController otherGaugeController = TextEditingController();

   // Facet Management (Se mantienen para la lógica de la UI de facetas)
   final List<Map<String, dynamic>> _facets = [];
   int _currentFacetIndex = 0;
   final TextEditingController _currentFacetNameController = TextEditingController();
   FacetOrientation _currentFacetOrientation = FacetOrientation.none;
   File? _currentFacetOverviewPhoto;
   final TextEditingController _currentReferenceMeasuredController = TextEditingController();
   final TextEditingController _currentPitchFacetController = TextEditingController();
  
   bool _currentStarterRowInstalled = false;
   bool _currentStarterEaveInstalled = false;
   File? _currentStarterEavePhoto;
   bool _currentStarterRakeInstalled = false;
   File? _currentStarterRakePhoto;

   bool _currentAtrPerformed = false;
   String? _currentAtrResult;
   File? _currentAtrPhoto;
   bool _currentHasValleyMetal = false;
   String? _currentValleyMetalType;
   File? _currentValleyMetalPhoto;

   final List<Map<String, dynamic>> _currentFacetVentsData = [];
   final List<TextEditingController> _currentVentCountControllers = [];
   final List<TextEditingController> _currentOtherVentSpecifyControllers = [];

    // Flashings por faceta (similar a vents)
   final List<Map<String, dynamic>> _currentFacetFlashingsData = [];
   final List<TextEditingController> _currentFlashingOtherControllers = [];

     // Other elements on the roof (por faceta)
  final List<Map<String, dynamic>> _currentFacetOtherElementsData = [];
  final List<TextEditingController> _currentOtherElementCountControllers = [];
  final List<TextEditingController> _currentOtherElementSpecifyControllers = [];
  
   bool _isLastFacet = false;

   final TextEditingController _currentFacetCommentController =
    TextEditingController();

   String _generateNextFacetName(FacetOrientation orientation) {
   final existingFacetsOfOrientation = _facets
      .where((f) => f['facetOrientation'] == orientation)
      .length;
    return '${orientation.name.substring(0, 1).toUpperCase()}'
      '${orientation.name.substring(1)}-${existingFacetsOfOrientation + 1}';
   }
    
     void _addNextFacet() {
      
    _formKey.currentState!.save();
    _saveCurrentFacetData();
    setState(() {
      _facets.add(_createNewFacetData());
      _currentFacetIndex = _facets.length - 1;
      _initializeCurrentFacet();
      _isLastFacet = false;
    });
   
   }
   Map<String, dynamic> _createNewVentData() {
    final countController = TextEditingController();
   final otherSpecifyController = TextEditingController();

   return {
    'type': null,
    'shouldBeChanged': false,
    'count': '',
    'includeSplitBoot': false,
    'includeLead': false,
    'otherSpecify': '',
    'photo': null,
    'countController': countController,
    'otherSpecifyController': otherSpecifyController,
  };
 }

 Map<String, dynamic> _createNewFlashingData() {
  final otherController = TextEditingController();
  return {
    'type': null,
    'material': null,
    'size': null,
    'finish': null,
    'grade': null,
    'shouldBeChanged': false,
    'otherSpecify': '',
    'photo': null,
    'otherController': otherController,
  };
 }

 Map<String, dynamic> _createNewOtherElementData() {
  final countController = TextEditingController();
  final otherSpecifyController = TextEditingController();
  return {
    'type': null,
    'count': '',
    'shouldBeChanged': false,
    'detachAndResetOnly': false,
    'otherSpecify': '',
    'photo': null,
    'countController': countController,
    'otherSpecifyController': otherSpecifyController,
  };
 }

 void _addAnotherVentToCurrentFacet() {
  setState(() {
    final newVent = _createNewVentData();
    _currentFacetVentsData.add(newVent);
    _currentVentCountControllers.add(newVent['countController']);
    _currentOtherVentSpecifyControllers.add(newVent['otherSpecifyController']);
  });
 }

  @override
  void initState() {
    super.initState();
    _initializeCurrentFacet();
  }
 Future<void> _pickImagesFromGallery() async {
  final pickedFiles = await picker.pickMultiImage(
    maxWidth: 1024,
    imageQuality: 80,
  );
  setState(() {
    for (var pickedFile in pickedFiles) {
      final img = File(pickedFile.path);
      photoReportImages.add(img);
      inspectionData.add({'label': 'User Image', 'path': img.path});
      widget.report.addPhoto(img, 'User Image');
    }
  });
 }
  // --- NUEVA FUNCIÓN DE FOTOS LIMPIA ---
 Future<void> _takePhoto(
  String label, {
  bool isFacetPhoto = false,
  int? facetIndex,
  bool isGlobal = false,
  int? ventIndex,
  int? flashingIndex,
 }) async {
  final pickedFile = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    imageQuality: 80,
  );

  if (pickedFile == null) return;

  final img = File(pickedFile.path);

  setState(() {
    // 1) Añadir siempre al modelo de reporte (para PDF de fotos)
    widget.report.addPhoto(img, label);

    // 2) Añadir a la lista local para thumbnails (si las sigues usando)
    photoReportImages.add(img);
    inspectionData.add({'label': label, 'path': img.path});

    // 3) Asignar según el contexto de la foto
    if (isGlobal) {
      if (label == 'Front Elevation Photo') {
        frontElevationPhoto = img;
        widget.report.frontElevationPhoto = img;
      } else if (label == 'Drip Edge Photo') {
        dripEdgePhoto = img;
        widget.report.dripEdgePhoto = img;
      } else if (label == 'Ridge Vent Photo') {
        globalRidgeVentPhoto = img;
        widget.report.globalRidgeVentPhoto = img;
      }
    } else if (isFacetPhoto && facetIndex != null) {
      // Fotos asociadas a una faceta concreta
      if (label == 'Overview Photo') {
        _facets[facetIndex]['overviewPicture'] = img;
        _currentFacetOverviewPhoto = img;
      } else if (label == 'Starter Row Eave Photo') {
        _facets[facetIndex]['starterEavePhoto'] = img;
        _currentStarterEavePhoto = img;
      } else if (label == 'Starter Row Rake Photo') {
        _facets[facetIndex]['starterRakePhoto'] = img;
        _currentStarterRakePhoto = img;
      } else if (label == 'ATR Photo') {
        _facets[facetIndex]['atrPhoto'] = img;
        _currentAtrPhoto = img;
      } else if (label == 'Valley Metal Photo') {
        _facets[facetIndex]['valleyMetalPhoto'] = img;
        _currentValleyMetalPhoto = img;
      }
    } else if (ventIndex != null && ventIndex < _currentFacetVentsData.length) {
      // Foto asociada a un vent específico
      _currentFacetVentsData[ventIndex]['photo'] = img;
    }
     else if (flashingIndex != null &&
        flashingIndex < _currentFacetFlashingsData.length) {
      // Foto asociada a un flashing específico
      _currentFacetFlashingsData[flashingIndex]['photo'] = img;
    }
  });
 }

  // --- SUBMIT FORM CORREGIDO ---
  void submitForm() async {

          // Validación personalizada de reemplazo de techo/sheathing
  if (roofCoverType == 'Shingles') {
    final partialShinglesText =
        _partialReplacementSqftController.text.trim();

    final hasFullShingles = fullRoofReplacementRequired;
    final hasPartialShingles = partialShinglesText.isNotEmpty;

    if (!hasFullShingles && !hasPartialShingles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Select full roof replacement or enter SF of shingles to replace.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (sheathingRequiredToBeChanged) {
      final partialSheathingText =
          _sheathingPartialSqftController.text.trim();

      final hasFullSheathing = sheathingFullReplacementRequired;
      final hasPartialSheathing = partialSheathingText.isNotEmpty;

      if (!hasFullSheathing && !hasPartialSheathing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Select full sheathing replacement or enter SF of sheathing to replace.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
  }
    if (_formKey.currentState!.validate()) {

       bool isValid = _formKey.currentState!.validate();
       debugPrint('Roof form validate() = $isValid');

  if (!isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please correct errors before submitting.'),
        backgroundColor: Colors.red,
      ),
    );
      }
      _formKey.currentState!.save();
      _saveCurrentFacetData(); // Guardar faceta actual en la lista
          // Sincronizar campos simples con el modelo
    widget.report.numLayers = numLayers;
    widget.report.estimatedAge = estimatedAge;
    widget.report.roofCoverType = roofCoverType;
    widget.report.roofSubType = roofSubType;
    widget.report.hasDripEdge = hasDripEdge;
    widget.report.dripEdgeType = dripEdgeType;
    //
    widget.report.hasShed = hasShed;
    widget.report.hasDetachedStructure = hasDetachedStructure;
    widget.report.hasGlobalRidgeVent = hasGlobalRidgeVent;
    widget.report.globalRidgeVentType = globalRidgeVentType;

      widget.report.fullRoofReplacementRequired = fullRoofReplacementRequired;
      widget.report.partialReplacementSqft =
      _partialReplacementSqftController.text.trim().isEmpty
          ? null
          : _partialReplacementSqftController.text.trim();
      widget.report.sheathingRequiredToBeChanged =
      sheathingRequiredToBeChanged;
      widget.report.sheathingFullReplacementRequired =
      sheathingFullReplacementRequired;
      widget.report.sheathingPartialReplacementSqft =
      _sheathingPartialSqftController.text.trim().isEmpty
          ? null
          : _sheathingPartialSqftController.text.trim();
       widget.report.sheathingType = sheathingType;
      widget.report.sheathingSize = sheathingSize;
      // Mostrar Cargando
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        // Generar PDFs usando el servicio externo
        final pdfs = await PdfService.generateReports(widget.report);
        
        if (!mounted) return;
        Navigator.pop(context); // Quitar Cargando

        // Mostrar opciones de envío
        _showSubmissionOptions(pdfs['tech']!, pdfs['photos']!);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDFs: $e')),
        );
      }
    }
  }
  // --- LOGICA DE FACETAS (Mantenida para funcionamiento) ---
  void _initializeCurrentFacet() {
    if (_facets.isEmpty) _facets.add(_createNewFacetData());
    final currentFacetData = _facets[_currentFacetIndex];
    _currentFacetNameController.text = currentFacetData['facetName'] ?? '';
    _currentFacetOrientation = currentFacetData['facetOrientation'] ?? FacetOrientation.none;
    _currentFacetOverviewPhoto = currentFacetData['overviewPicture'];
    _currentReferenceMeasuredController.text = currentFacetData['referenceMeasured'] ?? '';
    _currentStarterRowInstalled = currentFacetData['starterRowInstalled'] ?? false;
    _currentStarterEaveInstalled = currentFacetData['starterEaveInstalled'] ?? false;
    _currentStarterEavePhoto = currentFacetData['starterEavePhoto'];
    _currentStarterRakeInstalled = currentFacetData['starterRakeInstalled'] ?? false;
    _currentStarterRakePhoto = currentFacetData['starterRakePhoto'];
    _currentPitchFacetController.text = currentFacetData['pitchFacetValue'] ?? '';
    _currentAtrPerformed = currentFacetData['atrPerformed'] ?? false;
    _currentAtrResult = currentFacetData['atrResult'];
    _currentAtrPhoto = currentFacetData['atrPhoto'];
    _currentHasValleyMetal = currentFacetData['hasValleyMetal'] ?? false;
    _currentValleyMetalType = currentFacetData['valleyMetalType'];
    _currentValleyMetalPhoto = currentFacetData['valleyMetalPhoto'];
    _currentFacetCommentController.text = currentFacetData['comment'] ?? '';
                            // Vents: limpiar y recargar SIEMPRE
  _currentFacetVentsData.clear();
  _currentVentCountControllers.clear();
  _currentOtherVentSpecifyControllers.clear();

  final List<dynamic> loadedVents = currentFacetData['vents'] ?? [];
  for (final v in loadedVents) {
    final map = Map<String, dynamic>.from(v);
    final countController =
        TextEditingController(text: map['count'] ?? '');
    final otherSpecifyController =
        TextEditingController(text: map['otherSpecify'] ?? '');
    map['countController'] = countController;
    map['otherSpecifyController'] = otherSpecifyController;

    _currentFacetVentsData.add(map);
    _currentVentCountControllers.add(countController);
    _currentOtherVentSpecifyControllers.add(otherSpecifyController);
  }               
             // Flashings
    _currentFacetFlashingsData.clear();
    _currentFlashingOtherControllers.clear();
    final List<dynamic> loadedFlashings = currentFacetData['flashings'] ?? [];
    for (var f in loadedFlashings) {
      final map = Map<String, dynamic>.from(f);
      final otherController =
          TextEditingController(text: map['otherSpecify'] ?? '');
      map['otherController'] = otherController;
      _currentFacetFlashingsData.add(map);
      _currentFlashingOtherControllers.add(otherController);
    }
                // OTHER ELEMENTS
  _currentFacetOtherElementsData.clear();
  _currentOtherElementCountControllers.clear();
  _currentOtherElementSpecifyControllers.clear();
  final List<dynamic> loadedOther = currentFacetData['otherElements'] ?? [];
  for (final e in loadedOther) {
    final map = Map<String, dynamic>.from(e);
    final countController =
        TextEditingController(text: map['count'] ?? '');
    final otherSpecifyController =
        TextEditingController(text: map['otherSpecify'] ?? '');
    map['countController'] = countController;
    map['otherSpecifyController'] = otherSpecifyController;
    _currentFacetOtherElementsData.add(map);
    _currentOtherElementCountControllers.add(countController);
    _currentOtherElementSpecifyControllers.add(otherSpecifyController);
  }
  _currentFacetCommentController.text =
      currentFacetData['comment'] ?? '';
         }
         void _saveCurrentFacetData() {
        // Antes de guardar, sincronizar textos de 'Other' flashings
    for (int i = 0; i < _currentFacetFlashingsData.length; i++) {
      _currentFacetFlashingsData[i]['otherSpecify'] =
          _currentFlashingOtherControllers[i].text;
    }
                         // Sincronizar textos de 'Other' vents (si los tienes)
  for (int i = 0; i < _currentFacetVentsData.length; i++) {
    final vent = _currentFacetVentsData[i];
    if (vent['type'] == 'Other') {
      _currentFacetVentsData[i]['otherSpecify'] = _currentOtherVentSpecifyControllers[i].text;
          }
  }
                   for (int i = 0; i < _currentFacetOtherElementsData.length; i++) {
  _currentFacetOtherElementsData[i]['count'] =
      _currentOtherElementCountControllers[i].text;
  _currentFacetOtherElementsData[i]['otherSpecify'] =
      _currentOtherElementSpecifyControllers[i].text;
 }
  _facets[_currentFacetIndex] = {
    'facetName': _currentFacetNameController.text,
    'facetOrientation': _currentFacetOrientation,
    'overviewPicture': _currentFacetOverviewPhoto,
    'referenceMeasured': _currentReferenceMeasuredController.text,
    'starterRowInstalled': _currentStarterRowInstalled,
    'starterEaveInstalled': _currentStarterEaveInstalled,
    'starterEavePhoto': _currentStarterEavePhoto,
    'starterRakeInstalled': _currentStarterRakeInstalled,
    'starterRakePhoto': _currentStarterRakePhoto,
    'pitchFacetValue': _currentPitchFacetController.text,
    'atrPerformed': _currentAtrPerformed,
    'atrResult': _currentAtrResult,
    'atrPhoto': _currentAtrPhoto,
    'hasValleyMetal': _currentHasValleyMetal,
    'valleyMetalType': _currentValleyMetalType,
    'valleyMetalPhoto': _currentValleyMetalPhoto,
             'vents': _currentFacetVentsData
      .map((m) => Map<String, dynamic>.from(m))
      .toList(),
       'flashings': _currentFacetFlashingsData
      .map((m) {
        final copy = Map<String, dynamic>.from(m);
        // No queremos guardar los controllers dentro del map persistente
        copy.remove('otherController');
        return copy;
      })
      .toList(),

      'otherElements': _currentFacetOtherElementsData
        .map((m) {
          final copy = Map<String, dynamic>.from(m);
          copy.remove('countController');
          copy.remove('otherSpecifyController');
          return copy;
        })
        .toList(),
      'comment': _currentFacetCommentController.text,
  };
  widget.report.facets = _facets.map((f) {
    final orientation = f['facetOrientation'] as FacetOrientation;
                // Construir lista de FlashingData a partir del map
 final List<dynamic> rawFlashings = f['flashings'] ?? [];
 final flashings = rawFlashings.map((m) {
  final map = m as Map<String, dynamic>;
  return FlashingData(
    type: map['type'] ?? '',
    material: map['material'] as String?,
    size: map['size'] as String?,
    finish: map['finish'] as String?,
    grade: map['grade'] as String?,
    otherSpecify: map['otherSpecify'] as String?,
    shouldBeChanged: map['shouldBeChanged'] ?? false,
  );
 }).toList();
           // Vents
    final List<dynamic> rawVents = f['vents'] ?? [];
    final vents = rawVents.map((m) {
      final map = m as Map<String, dynamic>;
      return VentData(
        type: map['type'] ?? '',
        count: map['count'] as String?,
        shouldBeChanged: map['shouldBeChanged'] ?? false,
        includeSplitBoot: map['includeSplitBoot'] ?? false,
        includeLead: map['includeLead'] ?? false,
        otherSpecify: map['otherSpecify'] as String?,
      );
    }).toList();

    final List<dynamic> rawOther = f['otherElements'] ?? [];
 final otherElements = rawOther.map((m) {
  final map = m as Map<String, dynamic>;
  return OtherElementData(
    type: map['type'] ?? '',
    count: map['count'] as String?,
    shouldBeChanged: map['shouldBeChanged'] ?? false,
    detachAndResetOnly: map['detachAndResetOnly'] ?? false,
    otherSpecify: map['otherSpecify'] as String?,
  );
 }).toList();

    return FacetData(
      name: f['facetName'] ?? '',
      orientation: orientation.name,
      pitch: f['pitchFacetValue'] as String?,
      starterRowInstalled: f['starterRowInstalled'] ?? false,
      starterEaveInstalled: f['starterEaveInstalled'] ?? false,
      starterRakeInstalled: f['starterRakeInstalled'] ?? false,
      atrPerformed: f['atrPerformed'] ?? false,
      atrResult: f['atrResult'] as String?,
      hasValleyMetal: f['hasValleyMetal'] ?? false,
      valleyMetalType: f['valleyMetalType'] as String?,
      flashings: flashings,
      vents: vents,
      otherElements: otherElements,
      comment: f['comment'] as String?,
    );
  }).toList();
 }
             
  Map<String, dynamic> _createNewFacetData() {
    return {
      'facetName': '',
      'facetOrientation': FacetOrientation.none,
      'starterRowInstalled': false,
      'vents': [],
      'flashings': [],
      'otherElements': <Map<String, dynamic>>[], 
    };
  }

  Widget buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
    );
  }

  @override
  void dispose() {
    otherRoofCoverTypeController.dispose();
    otherMetalSubTypeController.dispose();
    otherGaugeController.dispose();
    _currentFacetNameController.dispose();
    _currentReferenceMeasuredController.dispose();
    _currentPitchFacetController.dispose();
    _currentFacetCommentController.dispose();
    _partialReplacementSqftController.dispose();
    _sheathingPartialSqftController.dispose();

      for (var controller in _currentOtherElementCountControllers) {
    controller.dispose();
  }
  for (var controller in _currentOtherElementSpecifyControllers) {
    controller.dispose();
  }

    // Dispose controllers for dynamically added vents
    for (var controller in _currentVentCountControllers) {
      controller.dispose();
    }
    for (var controller in _currentOtherVentSpecifyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final List<String> roofTypes = [
      'Shingles',
      'Metal',
      'Tile roofing',
      'Wood Shake',
      'Slate Roof',
      'TPO',
      'Modified Bitumen',
      'EPDM',
      'Roll Roofing',
      'Other',
    ];

    final Map<String, List<String>> subTypes = {
      'Shingles': ['Laminated', '3 Tab'],
      'Metal': [
        'Standing seam',
        'Corrugated',
        'Ribbed',
        'Wall/Roof Panel corrugated',
        'Other'
      ],
      'Tile roofing': ['Concrete', 'Clay'],
      'Wood Shake': ['Medium (1/2”)', 'Heavy (3/4”)'],
      'Slate Roof': ['Slate roofing (12 to 18) in', 'Slate roofing (12 to 24) in'],
      'TPO': [
        'Fully adhered system > 45 mil',
        'Fully adhered system > 60 mil',
        'Mech Att > 45 mil',
        'Mech Att > 60 mil',
        'Perimeter Adhered system > 45 mil',
        'Perimeter Adhered system > 60 mil',
      ],
      'Modified Bitumen': ['Hot mopped', 'Self-adhering'],
      'EPDM': [
        'Fully adhered system > 45 mil',
        'Fully adhered system > 60 mil',
        'Fully adhered system > 75 mil',
        'Fully adhered system > 90 mil',
        'Mech Att > 45 mil',
        'Mech Att > 60 mil',
        'Mech Att > 75 mil',
        'Mech Att > 90 mil',
        'Perimeter Adhered system > 45 mil',
        'Perimeter Adhered system > 60 mil',
        'Perimeter Adhered system > 75 mil',
        'Perimeter Adhered system > 90 mil',
      ],
      'Roll Roofing': ['Hot mopped', 'Self-adhering'],
    };

    final List<String> gaugeOptions = ['24', '26', '29', 'Other'];

    final List<String> ridgeVentTypes = ['Aluminum', 'Shingle over stile'];
    final List<String> atrResults = ['Passed', 'Failed'];
    final List<String> valleyMetalTypes = [
      'Valley metal',
      'Valley metal W profile',
      'Valley metal W profile painted',
      'Valley metal copper',
      'Valley metal painted'
    ];
    final List<String> ventTypes = [
      'Turtle vent Metal', 'Turtle vent Plastic', 'Pipe jack',
      'Exhaust through the roof up to 4”', 'Exhaust through the roof 6” to 8”',
      'Off ridge type 2”', 'Off ridge type 4”', 'Power attic vent',
      'Furnace Vent 5”', 'Furnace Vent 6”', 'Furnace Vent 8”',
      'Turbine type', 'Other'
    ];

  final isBasico = widget.plan != 'premium'; // muestra Upgrade para free/básico

  return Scaffold(
    appBar: AppBar(
      title: const Text('Roof Inspection'),
      actions: [
        if (isBasico)
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
                try {
                await StripeService.launchCheckout('premium');
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('No se pudo abrir Stripe Checkout: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(color: Colors.white),
            ),
          ),

             if (widget.plan == 'premium')
               IconButton(
               tooltip: 'My Reports',
               icon: const Icon(Icons.folder_open),
               onPressed: () {
               Navigator.of(context).push(
               MaterialPageRoute(builder: (_) => const MyReportsScreen()),
             );
              },
             ),

        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final navigator = Navigator.of(context);
              bool confirm = await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to sign out?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("LOGOUT")),
                ],
              ),
            ) ?? false;

            if (confirm) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              navigator.popUntil((route) => route.isFirst);
            }
          },
        ),
      ],
    ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              ElevatedButton(
                onPressed: () => _takePhoto('Front Elevation Photo', isGlobal: true),
                child: const Text("Take Front Elevation Photo"),
              ),
              const SizedBox(height: 20),
              const Text('Roof Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),

              // Type of Roof Cover Dropdown
              buildDropdown('Type of Roof Cover', roofTypes, roofCoverType,
                 
                  (val) {
                    widget.report.roofCoverType = val; // Sincronizar con el modelo
                    widget.report.roofSubType = null;
                    
                setState(() {
                  roofCoverType = val;
                  roofSubType = null;
                  selectedGauge = null;
                  otherRoofCoverTypeController.clear();
                  otherMetalSubTypeController.clear();
                  otherGaugeController.clear();
                  gravelBallastPresent = false;
                  _facets.clear();
                  _currentFacetIndex = 0;
                  _initializeCurrentFacet();
                  _isLastFacet = false; // Reset when adding a new facet
                });
              }),

              // TextField for 'Other' Roof Cover Type
              if (roofCoverType == 'Other')
                TextFormField(
                  controller: otherRoofCoverTypeController,
                  decoration: const InputDecoration(labelText: 'Specify Other Roof Type'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

              // Subtype Dropdown (second dropdown)
              if (roofCoverType != null && subTypes.containsKey(roofCoverType))
                buildDropdown('Subtype', subTypes[roofCoverType]!, roofSubType,
                    (val) {
                  setState(() {
                    roofSubType = val;
                    widget.report.roofSubType = val; // Sincronizar con el modelo
                    otherMetalSubTypeController.clear();
                    selectedGauge = null;
                    otherGaugeController.clear();
                  });
                }),


 if (roofCoverType == 'Shingles') ...[
                const SizedBox(height: 20),
 const Text(
    'Roof Replacement Scope',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 ),
 const Divider(),

 // Full roof replacement (roof cover)
 CheckboxListTile(
  title: const Text('Required full roof replacement?'),
  value: fullRoofReplacementRequired,
  onChanged: (val) {
    setState(() {
      fullRoofReplacementRequired = val ?? false;
      if (fullRoofReplacementRequired) {
        _partialReplacementSqftController.clear();
        partialReplacementSqft = null;
      }
    });
  },
 ),

 if (!fullRoofReplacementRequired)
  TextFormField(
    controller: _partialReplacementSqftController,
    decoration: const InputDecoration(
      labelText: 'How many SF of shingles require replacement?',
    ),
    keyboardType: TextInputType.number,
    onSaved: (val) => partialReplacementSqft = val,
  ),
 const SizedBox(height: 10),

 // Sheathing
 CheckboxListTile(
  title: const Text('Sheathing required to be changed?'),
  value: sheathingRequiredToBeChanged,
  onChanged: (val) {
    setState(() {
      sheathingRequiredToBeChanged = val ?? false;
      if (!sheathingRequiredToBeChanged) {
        sheathingFullReplacementRequired = false;
        _sheathingPartialSqftController.clear();
        sheathingPartialReplacementSqft = null;
        sheathingType = null;
        sheathingSize = null;
      }
    });
  },
 ),

 if (sheathingRequiredToBeChanged)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sheathing full/partial
 CheckboxListTile(
  title: const Text('Sheathing full replacement required?'),
  value: sheathingFullReplacementRequired,
  onChanged: (val) {
    setState(() {
      sheathingFullReplacementRequired = val ?? false;
      if (sheathingFullReplacementRequired) {
        _sheathingPartialSqftController.clear();
        sheathingPartialReplacementSqft = null;
      }
    });
  },
 ),

      if (!sheathingFullReplacementRequired)
        TextFormField(
          controller: _sheathingPartialSqftController,
          decoration: const InputDecoration(
            labelText: 'How many SF of sheathing require replacement?',
          ),
          keyboardType: TextInputType.number,
          onSaved: (val) =>
              sheathingPartialReplacementSqft = val,
        ),

      const SizedBox(height: 10),

      buildDropdown(
        'Sheathing type',
        ['OSB', 'CDX'],
        sheathingType,
        (val) => setState(() => sheathingType = val),
      ),
      buildDropdown(
        'Sheathing size',
        ['1/2"', '5/8"'],
        sheathingSize,
        (val) => setState(() => sheathingSize = val),
      ),
    ],
  ),
 const SizedBox(height: 20),
 ],
              // TextField for 'Other' Metal Subtype
              if (roofCoverType == 'Metal' && roofSubType == 'Other')
                TextFormField(
                  controller: otherMetalSubTypeController,
                  decoration: const InputDecoration(labelText: 'Specify Other Metal Subtype'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

              // Gauge Dropdown (third dropdown, only for Metal)
              if (roofCoverType == 'Metal' && roofSubType != null)
                buildDropdown('Gauge', gaugeOptions, selectedGauge, (val) {
                  setState(() {
                    selectedGauge = val;
                    otherGaugeController.clear();
                  });
                }),

              // TextField for 'Other' Gauge
              if (selectedGauge == 'Other')
                TextFormField(
                  controller: otherGaugeController,
                  decoration: const InputDecoration(labelText: 'Specify Other Gauge'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  
                ),

              // How many Layers Installed (Conditional)
              if (['Shingles', 'Modified Bitumen', 'Roll Roofing'].contains(roofCoverType))
                TextFormField(
                  decoration: const InputDecoration(labelText: 'How Many Layers Installed'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => numLayers = int.tryParse(val ?? '0') ?? 0,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  
                ),
               if (['Shingles'].contains(roofCoverType))
              TextFormField(
                decoration: const InputDecoration(labelText: 'Estimated Roof Age'),
                keyboardType: TextInputType.number,
                onSaved: (val) => estimatedAge = int.tryParse(val ?? '0') ?? 0,
              ),

                   const SizedBox(height: 20),
                   const Text(
                        'Additional Structures',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                   const Divider(),

                   CheckboxListTile(
                    title: const Text(
                           'There is a shed requiring roofing cover replacement up to 6 SQ)'),
                  value: hasShed,
                   onChanged: (val) {
                   setState(() {
                   hasShed = val ?? false;
                   widget.report.hasShed = hasShed;
             });
            },
          ),

 CheckboxListTile(
  title: const Text(
      'There is a larger structure or detached garage requiring roofing cover replacement'),
  value: hasDetachedStructure,
  onChanged: (val) {
    setState(() {
      hasDetachedStructure = val ?? false;
      widget.report.hasDetachedStructure = hasDetachedStructure;
    });
  },
 ),
              

              // Ridge Vent Installed? (Global)
              if (['Shingles'].contains(roofCoverType))
              CheckboxListTile(
                title: const Text('Is there Ridge Vent?'),
                value: hasGlobalRidgeVent,
                onChanged: (val) => setState(() {
                  hasGlobalRidgeVent = val!;
                  if (!hasGlobalRidgeVent) {
                    globalRidgeVentType = null;
                    globalRidgeVentPhoto = null;
                    widget.report.globalRidgeVentType = null;
                    widget.report.globalRidgeVentPhoto = null;
                  }
                }),
              ),
              if (hasGlobalRidgeVent)
                Column( 
                  children: [
                    buildDropdown('Ridge Vent Type', ridgeVentTypes,
                        globalRidgeVentType, (val) => setState(() => globalRidgeVentType = val)),
                    ElevatedButton(
                      onPressed: () => _takePhoto('Ridge Vent Photo', isGlobal: true),
                      child: const Text("Take Ridge Vent Photo"),
                    ),
                    TextButton(
                    onPressed: () => _takeExtraPhotoForLabel('Ridge Vent extra photo'),
                    child: const Text('Add extra Ridge Vent photo'),),
                    if (globalRidgeVentPhoto != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(globalRidgeVentPhoto!, height: 100),
                      ),
                  ],
                ),
                               
              // Drip Edge Installed? (Simplified)
              if (['Shingles'].contains(roofCoverType))
              CheckboxListTile(
                title: const Text('Drip Edge Installed?'),
                value: hasDripEdge,
                onChanged: (val) => setState(() {
                  hasDripEdge = val!;
                  if (!hasDripEdge) {
                    dripEdgeType = null;
                    dripEdgePhoto = null; 
                    widget.report.dripEdgeType = null;
                    widget.report.dripEdgePhoto = null;
                  }
                }),
              ),
              if (hasDripEdge) // Only show drip edge details if generally installed
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDropdown('Drip Edge Type', ['Standard', 'Gutter Apron', 'Copper'],
                        dripEdgeType, (val) {
                        setState(() {
                        dripEdgeType = val;
                         widget.report.dripEdgeType = val;
                         });
                        }),
                    ElevatedButton(
                      onPressed: () => _takePhoto('Drip Edge Photo', isGlobal: true), // Single photo button
                      child: const Text("Take Drip Edge Photo"),
                    ), 
                            TextButton(
                      onPressed: () => _takeExtraPhotoForLabel('Drip Edge extra photo'),
                      child: const Text('Add extra Drip Edge photo'),
                     ),

                    if (dripEdgePhoto != null) // Display single drip edge photo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(dripEdgePhoto!, height: 100),
                      ),
                  ],
                ),

              // Gravel ballast present checkbox (only for specific roof types)
              if (['Modified Bitumen', 'EPDM', 'Roll Roofing'].contains(roofCoverType))
                CheckboxListTile(
                  title: const Text('Gravel ballast present?'),
                  value: gravelBallastPresent,
                  onChanged: (bool? val) {
                    setState(() {
                      gravelBallastPresent = val!;
                     // widget.report.gravelBallastPresent = gravelBallastPresent;
                    });
                  },
                ),
              const SizedBox(height: 20),

              // --- Facet Inspection Section ---
              if (roofCoverType == 'Shingles' ||
                  roofCoverType == 'Metal' ||
                  roofCoverType == 'Tile roofing' ||
                  roofCoverType == 'Wood Shake' ||
                  roofCoverType == 'Slate Roof' ||
                  roofCoverType == 'TPO' ||
                  roofCoverType == 'Modified Bitumen' ||
                  roofCoverType == 'EPDM' ||
                  roofCoverType == 'Roll Roofing')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Facet Inspection',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Facet Navigation (if more than one facet)
                    if (_facets.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _currentFacetIndex > 0
                                ? () {
                                    _saveCurrentFacetData();
                                    setState(() {
                                      _currentFacetIndex--;
                                      _initializeCurrentFacet();
                                    });
                                  }
                                : null,
                            child: const Text('Previous Facet'),
                          ),
                          Text(
                              'Facet ${_currentFacetIndex + 1} of ${_facets.length}'),
                          ElevatedButton(
                            onPressed: _currentFacetIndex < _facets.length - 1
                                ? () {
                                    _saveCurrentFacetData();
                                    setState(() {
                                      _currentFacetIndex++;
                                      _initializeCurrentFacet();
                                    });
                                  }
                                : null,
                            child: const Text('Next Facet'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),

                    Text('Current Facet: ${_currentFacetNameController.text}',
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

 buildDropdown(
  'Facet Orientation',
  FacetOrientation.values
      .map((e) => e.name)
      .where((name) => name != 'none')
      .toList(),
  _currentFacetOrientation == FacetOrientation.none
      ? null
      : _currentFacetOrientation.name,
  (val) {
    setState(() {
      _currentFacetOrientation = FacetOrientation.values
          .firstWhere((e) => e.name == val);
      // Auto-fill facet name based on orientation
      if (val != null) {
        _currentFacetNameController.text =
            _generateNextFacetName(_currentFacetOrientation);
      }
    });
  },
 ),

                  TextFormField(
                   controller: _currentFacetNameController,
                    decoration: const InputDecoration(labelText: 'Facet Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (val) => _facets[_currentFacetIndex]['facetName'] = val,
                  ),
                    TextFormField(
                      controller: _currentPitchFacetController,
                      decoration: const InputDecoration(labelText: 'Pitch of Facet'),
                                            onSaved: (val) =>
                          _facets[_currentFacetIndex]['pitchFacetValue'] = val,
                    ),
                    ElevatedButton(
                      onPressed: () => _takePhoto('Overview Photo',
                          isFacetPhoto: true, facetIndex: _currentFacetIndex),
                      child: const Text("Take Facet Overview Photo"),
                    ),
                    if (_currentFacetOverviewPhoto != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(_currentFacetOverviewPhoto!, height: 100),
                      ),

                   // Starter Row Questions for current facet
                    CheckboxListTile(
                      title: const Text('Starter Row Installed?'),
                      value: _currentStarterRowInstalled,
                      onChanged: (val) => setState(() {
                        _currentStarterRowInstalled = val!;
                        if (!val) {
                          _currentStarterEaveInstalled = false;
                          _currentStarterEavePhoto = null;
                          _currentStarterRakeInstalled = false;
                          _currentStarterRakePhoto = null;
                        }
                      }),
                    ),
                    if (_currentStarterRowInstalled)
                      Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('Starter Row at Eave?'),
                            value: _currentStarterEaveInstalled,
                            onChanged: (val) => setState(() {
                              _currentStarterEaveInstalled = val!;
                              if (!val) _currentStarterEavePhoto = null;
                            }),
                          ),
                          if (_currentStarterEaveInstalled)
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _takePhoto('Starter Row Eave Photo',
                                      isFacetPhoto: true, facetIndex: _currentFacetIndex),
                                  child: const Text("Take Starter Row Eave Photo"),
                                ),
                                TextButton(onPressed: () => _takeExtraPhotoForLabel('Starter row at Eave extra photo'),
                                child: const Text('Add extra Starter row at Eave photo'),),
                                if (_currentStarterEavePhoto != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Image.file(_currentStarterEavePhoto!, height: 100),
                                  ),
                              ],
                            ),
                          CheckboxListTile(
                            title: const Text('Starter Row at Rake?'),
                            value: _currentStarterRakeInstalled,
                            onChanged: (val) => setState(() {
                              _currentStarterRakeInstalled = val!;
                              if (!val) _currentStarterRakePhoto = null;
                            }),
                          ),
                          if (_currentStarterRakeInstalled)
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _takePhoto('Starter Row Rake Photo',
                                      isFacetPhoto: true, facetIndex: _currentFacetIndex),
                                  child: const Text("Take Starter Row Rake Photo"),
                                ),
                                 TextButton(onPressed: () => _takeExtraPhotoForLabel('Starter row at Rake extra photo'),
                                child: const Text('Add extra Starter row at Rake photo'),),
                                if (_currentStarterRakePhoto != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Image.file(_currentStarterRakePhoto!, height: 100),
                                  ),
                              ],
                            ),
                        ],
                      ),
                 
                    CheckboxListTile(
                      title: const Text('ATR Performed?'),
                      value: _currentAtrPerformed,
                      onChanged: (val) => setState(() {
                        _currentAtrPerformed = val!;
                        if (!val) {
                          _currentAtrResult = null;
                          _currentAtrPhoto = null;
                        }
                      }),
                    ),
                    if (_currentAtrPerformed)
                      Column(
                        children: [
                          buildDropdown('ATR Result', atrResults, _currentAtrResult,
                              (val) => setState(() => _currentAtrResult = val)),
                          ElevatedButton(
                            onPressed: () => _takePhoto('ATR Photo',
                                isFacetPhoto: true, facetIndex: _currentFacetIndex),
                            child: const Text("Take ATR Photo"),
                          ),
                           TextButton(onPressed: () => _takeExtraPhotoForLabel('ATR extra photo'),
                                child: const Text('Add extra ATR photo'),),
                          if (_currentAtrPhoto != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.file(_currentAtrPhoto!, height: 100),
                            ),
                        ],
                      ),
                    CheckboxListTile(
                      title: const Text('Has Valley Metal?'),
                      value: _currentHasValleyMetal,
                      onChanged: (val) => setState(() {
                        _currentHasValleyMetal = val!;
                        if (!val) {
                          _currentValleyMetalType = null;
                          _currentValleyMetalPhoto = null;
                        }
                      }),
                    ),
                    if (_currentHasValleyMetal)
                      Column(
                        children: [
                          buildDropdown('Valley Metal Type', valleyMetalTypes,
                              _currentValleyMetalType, (val) => setState(() => _currentValleyMetalType = val)),
                          ElevatedButton(
                            onPressed: () => _takePhoto('Valley Metal Photo',
                                isFacetPhoto: true, facetIndex: _currentFacetIndex),
                            child: const Text("Take Valley Metal Photo"),
                          ),
                           TextButton(onPressed: () => _takeExtraPhotoForLabel('Valley Metal extra photo'),
                                child: const Text('Add extra Valley Metal photo'),),
                          if (_currentValleyMetalPhoto != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.file(_currentValleyMetalPhoto!, height: 100),
                            ),
                        ],
                      ),

                        
                        const SizedBox(height: 20),
 const Text(
  'Flashings on Facet',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 ),
 const Divider(),

 // Lista de flashings
 ..._currentFacetFlashingsData.asMap().entries.map((entry) {
  final idx = entry.key;
  final data = entry.value;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flashing ${idx + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    data['otherController'].dispose();
                    _currentFlashingOtherControllers.removeAt(idx);
                    _currentFacetFlashingsData.removeAt(idx);
                  });
                },
              ),
            ],
          ),
          buildDropdown(
            'Flashing Type',
            [
              'Step flashing',
              'Flashing kick-out divert',
              'Ridge flashing',
              'Counter/Apron flashing',
              'Wide flashing',
              'Sidewall/Endwall flashing',
              'L flashing',
              'Chimney flashing',
              'Roof window step flashing kit',
              'Skylight flashing kit (dome)',
              'Other',
            ],
               data['type'],
  (val) {
    setState(() {
      data['type'] = val;
      // Limpiar campos dependientes
      data['material'] = null;
      data['size'] = null;
      data['finish'] = null;
      data['grade'] = null;
      data['otherSpecify'] = '';
      // Si quieres, también limpiar el controller de "Other"
      if (data['otherController'] is TextEditingController) {
        (data['otherController'] as TextEditingController).clear();
      }
    });
  },
          ),
          if (data['type'] == 'Other')
            TextFormField(
              controller: data['otherController'],
              decoration: const InputDecoration(labelText: 'Specify Other Flashing'),
              onSaved: (val) => data['otherSpecify'] = val,
            ),
            _buildFlashingSubfields(data),
          CheckboxListTile(
            title: const Text('Should be changed?'),
            value: data['shouldBeChanged'],
            onChanged: (val) =>
                setState(() => data['shouldBeChanged'] = val ?? false),
          ),
          ElevatedButton(
            onPressed: () => _takePhoto(
              'Flashing Photo ${idx + 1}',
           flashingIndex: idx,
            ),
            child: const Text("Take Flashing Photo"),
                      ),
           TextButton(onPressed: () => _takeExtraPhotoForLabel('Flashing extra photo'),
                                child: const Text('Add extra Flashing photo'),),
                                          if (data['photo'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.file(data['photo']!, height: 100),
            ),
        ],
      ),
    ),
  );
  }),
                    ElevatedButton(
  onPressed: () {
    setState(() {
      final f = _createNewFlashingData();
      _currentFacetFlashingsData.add(f);
      _currentFlashingOtherControllers.add(f['otherController']);
    });
  },
  child: const Text('Add Flashing'),
 ),

 const SizedBox(height: 20),

                     // Luego viene 'Vents on Facet'
                    const SizedBox(height: 20),
                    const Text('Vents on Facet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Dynamically added vent sections
                    ..._currentFacetVentsData.asMap().entries.map((entry) {
                      int ventIndex = entry.key;
                      Map<String, dynamic> ventData = entry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Vent ${ventIndex + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        // Dispose controllers before removing
                                        ventData['countController'].dispose();
                                        ventData['otherSpecifyController'].dispose();
                                        _currentVentCountControllers.removeAt(ventIndex);
                                        _currentOtherVentSpecifyControllers.removeAt(ventIndex);
                                        _currentFacetVentsData.removeAt(ventIndex);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              buildDropdown(
                                'Vent Type',
                                ventTypes,
                                ventData['type'],
                                (val) => setState(() => ventData['type'] = val),
                              ),
                              CheckboxListTile(
                                title: const Text('Should be Changed?'),
                                value: ventData['shouldBeChanged'],
                                onChanged: (val) =>
                                    setState(() => ventData['shouldBeChanged'] = val!),
                              ),
                              if (ventData['type'] != 'Other') // FIX: Removed unnecessary null comparison
                                TextFormField(
                                  controller: ventData['countController'],
                                  decoration:
                                      InputDecoration(labelText: 'Count of ${ventData['type']}'),
                                  keyboardType: TextInputType.number,
                                  onSaved: (val) => ventData['count'] = val,
                                ),
                              if (ventData['type'] == 'Pipe jack')
                                Column(
                                  children: [
                                    CheckboxListTile(
                                      title: const Text('Include Split Boot?'),
                                      value: ventData['includeSplitBoot'],
                                      onChanged: (val) =>
                                          setState(() => ventData['includeSplitBoot'] = val!),
                                    ),
                                    CheckboxListTile(
                                      title: const Text('Include Lead?'),
                                      value: ventData['includeLead'],
                                      onChanged: (val) =>
                                          setState(() => ventData['includeLead'] = val!),
                                    ),
                                  ],
                                ),
                              if (ventData['type'] == 'Other')
                                TextFormField(
                                  controller: ventData['otherSpecifyController'],
                                  decoration:
                                      const InputDecoration(labelText: 'Specify Other Vent'),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                  onSaved: (val) => ventData['otherSpecify'] = val,
                                ),
                              ElevatedButton(
                                onPressed: () => _takePhoto('Vent Photo ${ventIndex + 1}',
                                    ventIndex: ventIndex),
                                child: const Text("Take Vent Photo"),
                              ),
                               TextButton(onPressed: () => _takeExtraPhotoForLabel('Vent extra photo'),
                                child: const Text('Add extra Vent photo'),),
                              if (ventData['photo'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Image.file(ventData['photo']!, height: 100),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),//toList(),
                               
                    ElevatedButton(
                      onPressed: _addAnotherVentToCurrentFacet,
                      child: const Text('Add Vent'),
                    ),

                                const SizedBox(height: 20),
 const Text(
  'Other elements on the roof',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 ),
 const Divider(),

 // Lista de Other elements
 ..._currentFacetOtherElementsData.asMap().entries.map((entry) {
  final idx = entry.key;
  final data = entry.value;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Element ${idx + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    data['countController'].dispose();
                    data['otherSpecifyController'].dispose();
                    _currentOtherElementCountControllers.removeAt(idx);
                    _currentOtherElementSpecifyControllers.removeAt(idx);
                    _currentFacetOtherElementsData.removeAt(idx);
                  });
                },
              ),
            ],
          ),
          buildDropdown(
            'Element Type',
            [
              'Snow guard/stop',
              'Snow bar - powder coated',
              'Snow panel - aluminum',
              'Snow panel rake cap - aluminum',
              'Skylight',
              'Evaporative cooler',
              'Air condenser w/pad',
              'Solar electric panel',
              'Water heater panel',
              'Satellite dishes',
              'AC Units',
              'Meter mast for overhead power – conduit',
              'Other',
            ],
            data['type'],
            (val) => setState(() => data['type'] = val),
          ),
          TextFormField(
            controller: data['countController'],
            decoration: const InputDecoration(
              labelText: 'Count',
            ),
            keyboardType: TextInputType.number,
            onSaved: (val) => data['count'] = val,
          ),
          if (data['type'] == 'Other')
            TextFormField(
              controller: data['otherSpecifyController'],
              decoration:
                  const InputDecoration(labelText: 'Specify Other element'),
              onSaved: (val) => data['otherSpecify'] = val,
            ),

          // Exclusivo: Should be changed vs Detach & Reset only
          CheckboxListTile(
            title: const Text('Should be changed?'),
            value: data['shouldBeChanged'],
            onChanged: (val) {
              setState(() {
                data['shouldBeChanged'] = val ?? false;
                if (data['shouldBeChanged'] == true) {
                  data['detachAndResetOnly'] = false;
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Detach & Reset only'),
            value: data['detachAndResetOnly'],
            onChanged: (val) {
              setState(() {
                data['detachAndResetOnly'] = val ?? false;
                if (data['detachAndResetOnly'] == true) {
                  data['shouldBeChanged'] = false;
                }
              });
            },
          ),

          ElevatedButton(
            onPressed: () => _takePhoto(
              'Other element photo ${idx + 1}',
              // podrías añadir otro índice específico si quisieras
            ),
            child: const Text("Take element photo"),
          ),
          if (data['photo'] != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.file(data['photo'] as File, height: 100),
            ),
        ],
      ),
    ),
  );
 }),

 ElevatedButton(
  onPressed: () {
    setState(() {
      final e = _createNewOtherElementData();
      _currentFacetOtherElementsData.add(e);
      _currentOtherElementCountControllers.add(e['countController']);
      _currentOtherElementSpecifyControllers
          .add(e['otherSpecifyController']);
    });
  },
  child: const Text('Add Other element'),
 ),

                    const SizedBox(height: 20),
                          const Divider(),
                           ElevatedButton.icon(
                            onPressed: () {
                       final facetName = _currentFacetNameController.text.isNotEmpty
                       ? _currentFacetNameController.text
                                                     : 'Unnamed facet';
                          _takeExtraPhotoForLabel('Facet $facetName - additional photo');
                            },
                                                        icon: const Icon(Icons.add_a_photo),
                         label: const Text('Take additional photo of this facet'),
                             ),
                                       const SizedBox(height: 20),
                               // Campo de texto para comentarios de la faceta actual
                                      const SizedBox(height: 20),
                                       const Text(
                                      'Additional comment on this facet',
                                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                     ),
                                      const Divider(),
                                    TextFormField(
                                     controller: _currentFacetCommentController,
                                      decoration: const InputDecoration(
                                        labelText: 'Comment',
                                        alignLabelWithHint: true,
                                         ),
                                         maxLines: 3,
                                        ),
                                        const SizedBox(height: 20),

                                                         // Checkbox para indicar que es la última faceta (ya existente)
                    CheckboxListTile(
                      title: const Text('This is the Last Facet'),
                      value: _isLastFacet,
                      onChanged: (val) {
                        setState(() {
                          _isLastFacet = val!;
                        });
                      },
                    ),
                                    
                    // NUEVO: Botón "Add more Images to the report?" condicional
                    if (_isLastFacet) ...[
                      const SizedBox(height: 20),
                      const Text('Photo Report - Additional Images',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ElevatedButton.icon(
                        onPressed: _pickImagesFromGallery, // Llama al nuevo método para galería
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text("Add Images from your gallery?"),
                      ),
                      const SizedBox(height: 10),
                      // Mostrar miniaturas de las imágenes seleccionadas de la galería
                      if (photoReportImages.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Imágenes añadidas al reporte:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8.0, // Espacio entre imágenes
                              runSpacing: 4.0, // Espacio entre líneas de imágenes
                              children: photoReportImages.where((imageFile) {
                                // Filtra las imágenes que no son de la galería si quieres mostrar solo las "User Images" aquí
                                // Por simplicidad, aquí está mostrando todas las fotos que están en photoReportImages
                                return true; 
                              }).map((imageFile) {
                                return Stack(
                                  children: [
                                    Image.file(imageFile, height: 80, width: 80, fit: BoxFit.cover),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            photoReportImages.remove(imageFile);
                                            // También remover del inspectionData si es necesario para tu lógica
                                            inspectionData.removeWhere((element) => element['path'] == imageFile.path && element['label'] == 'User Image');
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                    ],

                    // Next Facet / Submit Buttons
 Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    // Botón "Add Next Facet" solo visible si no es la última faceta
    if (!_isLastFacet)
      ElevatedButton(
        onPressed: _addNextFacet,
        child: const Text('Add Next Facet'),
      ),

      if(_isLastFacet)
   ElevatedButton(
  onPressed: submitForm,
  child: const Text(
    'Submit Estimate',
    style: TextStyle(fontSize: 18),
  ),
 ),
  ],
  ),

 const SizedBox(height: 40),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

