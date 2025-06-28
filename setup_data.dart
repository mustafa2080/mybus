import 'package:firebase_core/firebase_core.dart';
import 'lib/utils/firebase_setup.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Setup initial data
  await FirebaseSetup.setupInitialData();
  
  print('✅ تم إعداد البيانات الأولية بنجاح!');
}
