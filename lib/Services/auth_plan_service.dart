import 'package:firebase_auth/firebase_auth.dart';

// ----------------------------------------------------------------------
// FUNCIÓN CLAVE: Leer el Custom Claim del token
// ----------------------------------------------------------------------

/// Obtiene el estado actual del plan del usuario (basico, premium, anonimo).
///
/// [forceRefresh] debe ser TRUE cuando se espera un cambio de plan 
/// (ej: justo después del login, o después de un pago con Stripe).
Future<String> getUserPlanStatus({bool forceRefresh = false}) async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return 'anonimo'; 
  }

  try {
    // Esto hace la llamada a Firebase para obtener la información más reciente del token,
    // incluyendo el Custom Claim 'plan'.
    final idTokenResult = await user.getIdTokenResult(forceRefresh); 

    // Leer el valor del claim 'plan'
    final userPlan = idTokenResult.claims?['plan'] as String?; 
    
    // Si el claim existe, lo devuelve; si no, asume el 'basico' por defecto.
    return userPlan ?? 'basico'; 
    
  } catch (e) {
    print("Error al obtener los Custom Claims: $e");
    return 'error';
  }
}