// lib/services/stripe_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';   

 class StripeService {
  static Future<void> launchCheckout(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    final callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');

    final result = await callable.call({
      'priceId': plan == 'premium'
          ? 'price_1SXPEDIV8TkU9SxHEMLdOOPO'   // PREMIUM
          : 'price_1SXPDkIV8TkU9SxHb9qzNc4R',  // BÁSICO
      'successUrl': 'claimscope://success',
      'cancelUrl': 'claimscope://cancel',
    });
           //codigo con errores:
    //final sessionId = result.data['sessionId'] as String;
    //final url = Uri.parse('https://checkout.stripe.com/c/pay/$sessionId');
        // CÓDIGO CORREGIDO:
    final sessionUrl = result.data['url'] as String?; // Esperamos la clave 'url'
    
    if (sessionUrl == null) {
      throw Exception("La función no devolvió la URL de Stripe.");
    }
    
    final url = Uri.parse(sessionUrl); // ⬅️ ¡Usar la URL devuelta!  
     // ⭐️ CAMBIO 2: Usar launchUrl sin canLaunchUrl (más fiable en Flutter reciente) 
    // y usar LaunchMode.inAppWebView o LaunchMode.externalApplication
    
    try {
        // Se recomienda usar launchUrl directamente con un modo de lanzamiento 
        // para manejar el fallback en caso de que no haya navegador disponible.
        // Usamos externalApplication para que se abra en el navegador por defecto del usuario.
        final success = await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
        );

        if (!success) {
           throw Exception("launchUrl falló al iniciar el navegador.");
        }
    } catch (e) {
      // El error de Flutter "No se pudo abrir Stripe Checkout" se debe a que 
      // launchUrl es más estricto o no encuentra el componente.
      throw Exception("No se pudo abrir Stripe Checkout: $e");
    }
  }
}

         //codogo original con errores comentade:
      // Ahora canLaunchUrl y LaunchMode están definidos
     // if (await canLaunchUrl(url)) {
     // await launchUrl(url, mode: LaunchMode.externalApplication);
      //} else {
      //throw Exception("No se pudo abrir Stripe Checkout");
     // }
      //}
      //}