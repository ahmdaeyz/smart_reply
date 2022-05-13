import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:mb_smart_reply/firebase_options.dart';
import 'package:mb_smart_reply/pages/rooms_page.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Reply',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providerConfigs: const [
              EmailProviderConfiguration(),
            ],
            actions: [
              AuthStateChangeAction<UserCreated>((context, state) async {
                var faker = Faker();
                await FirebaseChatCore.instance.createUserInFirestore(
                  types.User(
                    firstName: faker.person.firstName(),
                    id: state.credential.user!.uid,
                    imageUrl:
                        'https://i.pravatar.cc/300?u=${state.credential.user?.email ?? ""}',
                    lastName: faker.person.lastName(),
                  ),
                );
              })
            ],
          );
        }
        return const RoomsPage();
      },
    );
  }
}
