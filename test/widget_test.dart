import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misoles_labactivity7/demo_auth.dart';
import 'package:misoles_labactivity7/login_screen.dart';
import 'package:misoles_labactivity7/main.dart';
import 'package:misoles_labactivity7/social_media/create_post_sheet.dart';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    return null;
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    return null;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDown(() {
    DemoAuth.logout();
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
  });

  testWidgets('Test 1 to 14: Complete Step 11 Application Flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Test 1: Open the application. Login appears first.
    await tester.pumpWidget(const StudentApp());
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Test 2: Submit empty login fields. Validation messages appear.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    // Test 3: Enter incorrect credentials. Login is rejected.
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'wrong_user');
    await tester.enterText(loginFields.at(1), 'wrong_pass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Invalid username or password.'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(LoginScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // Test 4: Enter admin / admin123. Dashboard opens.
    await tester.enterText(loginFields.at(0), 'admin');
    await tester.enterText(loginFields.at(1), 'admin123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);

    // Test 5: Read the dashboard greeting. Displays Welcome, admin!
    expect(find.text('Welcome, admin!'), findsOneWidget);
    expect(
      find.text(
        'Explore your student application using the navigation bar below.',
      ),
      findsOneWidget,
    );

    // Test 6: Open Calculator and calculate 10 + 5. Displays 15.0.
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Calculator'), findsWidgets);

    final calcInputs = find.byType(TextFormField);
    await tester.enterText(calcInputs.at(0), '10');
    await tester.enterText(calcInputs.at(1), '5');
    await tester.tap(find.widgetWithText(ElevatedButton, '+'));
    await tester.pumpAndSettle();
    expect(find.text('15.0'), findsOneWidget);

    // Test 7: Switch tabs and return to Calculator. Inputs and result remain.
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, admin!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('15.0'), findsOneWidget);

    // Test 8: Create a social post. Post displays the logged-in username.
    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();
    expect(find.text('Social Media'), findsWidgets);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);

    final captionInput = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(0);
    final imageInput = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(1);

    await tester.enterText(captionInput, 'Hello from admin post!');
    await tester.enterText(
      imageInput,
      'https://picsum.photos/id/20/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Hello from admin post!'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);

    // Test 9: Like a post and add a comment. Both interactions update correctly.
    final likeButtons = find.widgetWithText(TextButton, 'Like');
    await tester.tap(likeButtons.first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Liked'), findsOneWidget);

    final commentFields =
        find.widgetWithText(TextField, 'Add a comment...');
    final sendButtons = find.byIcon(Icons.send);
    await tester.enterText(commentFields.first, 'Great post admin!');
    await tester.tap(sendButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('1 Comments'), findsOneWidget);
    expect(find.text('Great post admin!'), findsOneWidget);

    // Test 10: Switch tabs and return to Social. Posts, likes, and comments remain.
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, admin!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();
    expect(find.text('Hello from admin post!'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Liked'), findsOneWidget);
    expect(find.text('1 Comments'), findsOneWidget);
    expect(find.text('Great post admin!'), findsOneWidget);

    // Test 11: Open Profile. Student information and username appear.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Student Profile'), findsWidgets);
    expect(find.text('Yuan Misoles'), findsOneWidget);
    expect(find.text('Logged in as: admin'), findsOneWidget);
    expect(find.text('555062'), findsOneWidget);
    expect(find.text('BSIT — 3447'), findsOneWidget);
    expect(find.text('yuanmisoles23@gmail.com'), findsOneWidget);

    // Test 12: Tap Logout. Login appears; Back does not reopen MainScreen.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Test 13: Register a valid account and log in. Dashboard displays registered username.
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    final registerInputs = find.byType(TextFormField);
    await tester.enterText(registerInputs.at(0), 'juan_delacruz');
    await tester.enterText(registerInputs.at(1), 'password123');
    await tester.enterText(registerInputs.at(2), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    ScaffoldMessenger.of(tester.element(find.byType(LoginScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    final loginInputs2 = find.byType(TextFormField);
    await tester.enterText(loginInputs2.at(0), 'juan_delacruz');
    await tester.enterText(loginInputs2.at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Welcome, juan_delacruz!'), findsOneWidget);

    // Test 14: Create a post using the registered account. Post displays registered username.
    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final captionInput2 = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(0);
    final imageInput2 = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(1);

    await tester.enterText(captionInput2, 'Post created by Juan!');
    await tester.enterText(
      imageInput2,
      'https://picsum.photos/id/21/600/400',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Post created by Juan!'), findsOneWidget);
    expect(find.text('juan_delacruz'), findsOneWidget);
  });
}
