import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/admin/settings/presentation/more_modules_screen.dart';
import 'package:parkiko/features/admin/sites/presentation/add_site_wizard_screen.dart';
import 'package:parkiko/features/admin/sites/services/site_manager.dart';

void main() {
  testWidgets('MoreModulesScreen renders all elements matching HTML design faithfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool logoutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MoreModulesScreen(
          onLogout: () {
            logoutCalled = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Top App Bar
    expect(find.text('Parkiko'), findsOneWidget);
    expect(find.byIcon(Icons.local_parking), findsOneWidget);

    // 2. Verify Page Header Label & Admin Badge
    expect(find.text('More Options'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);

    // 3. Verify User Profile Quick Summary Card
    expect(find.text('VR'), findsOneWidget);
    expect(find.text('Vikram R.'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user), findsOneWidget);
    expect(find.text('admin@parkiko.com'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // 4. Verify Multi-Site Valet Operations
    expect(find.text('MULTI-SITE VALET OPERATIONS'), findsOneWidget);
    expect(find.text('Add Multi-Site'), findsOneWidget);
    expect(find.text('New Hub'), findsOneWidget);
    expect(
      find.text('Onboard new property, configure decks, bays and operational layout'),
      findsOneWidget,
    );

    // 5. Verify System Configuration & Security
    expect(find.text('SYSTEM CONFIGURATION & SECURITY'), findsOneWidget);
    expect(find.text('Settings & Security'), findsOneWidget);
    expect(
      find.text('WhatsApp API gateway, POS terminal safeguards, 2FA and role permissions'),
      findsOneWidget,
    );

    // 6. Verify Log Out button and subtle build info
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('Parkiko Valet v4.18.2 (Build 942)'), findsOneWidget);

    // 7. Interactive Test: Open Settings & Security modal
    await tester.tap(find.text('Settings & Security'));
    await tester.pumpAndSettle();

    expect(find.text('Biometric Quick Authentication'), findsOneWidget);
    expect(find.text('Offline Local Sync Mode'), findsOneWidget);
    expect(find.text('WhatsApp API Gateway Slips'), findsOneWidget);
    expect(find.text('POS Terminal Safeguards'), findsOneWidget);
    expect(find.text('Two-Factor Auth (2FA)'), findsOneWidget);

    // Toggle biometric switch
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(5));
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    // Close settings modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 8. Interactive Test: Open Edit Profile modal and edit name
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Admin Profile'), findsOneWidget);
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(3));

    await tester.enterText(textFields.at(0), 'Vikram Rao');
    await tester.tap(find.text('Save Profile Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Vikram Rao'), findsOneWidget);

    // 9. Interactive Test: Tap Add Multi-Site navigates to AddSiteWizardScreen
    await tester.tap(find.text('Add Multi-Site'));
    await tester.pumpAndSettle();
    expect(find.byType(AddSiteWizardScreen), findsOneWidget);

    // Navigate back to More screen
    Navigator.of(tester.element(find.byType(AddSiteWizardScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('More Options'), findsOneWidget);

    // 10. Interactive Test: Tap Log Out triggers confirmation dialog
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Out of Terminal?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to sign out of the Parkiko Admin operations terminal?'),
      findsOneWidget,
    );

    // Click Log Out in dialog
    final dialogLogoutBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Log Out'),
    );
    await tester.tap(dialogLogoutBtn);
    await tester.pumpAndSettle();

    expect(logoutCalled, isTrue);
  });

  testWidgets('Clicking on site allows deactivating, activating, and deleting from database', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Setup a site
    final testSite = SiteModel(
      id: 'site_test_actions',
      name: 'Westin Gurgaon Hub',
      address: 'MG Road, Sector 29, Gurugram',
      totalBays: 120,
      baseFee: 200,
      status: 'active',
      createdAt: DateTime.now(),
    );
    SiteManager.instance.addSite(testSite);
    SiteManager.instance.selectSite(testSite.name);

    await tester.pumpWidget(
      MaterialApp(
        home: MoreModulesScreen(
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify the site card exists and displays Active status
    expect(find.text('Westin Gurgaon Hub'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    // 2. Click on the site card to open Site Actions Modal
    await tester.tap(find.byKey(const Key('site_card_site_test_actions')));
    await tester.pumpAndSettle();

    // Verify modal options
    expect(find.byKey(const Key('btn_select_site_site_test_actions')), findsOneWidget);
    expect(find.text('Currently Selected Site'), findsOneWidget);
    expect(find.text('Deactivate Site'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // 3. Deactivate Site
    await tester.tap(find.byKey(const Key('btn_toggle_status_site_test_actions')));
    await tester.pumpAndSettle();

    expect(find.text('Site "Westin Gurgaon Hub" has been deactivated'), findsOneWidget);
    expect(SiteManager.instance.sites.firstWhere((s) => s.id == 'site_test_actions').status, 'inactive');
    expect(find.text('Inactive'), findsWidgets);

    ScaffoldMessenger.of(tester.element(find.byType(MoreModulesScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // 4. Click site card again and activate it
    await tester.tap(find.byKey(const Key('site_card_site_test_actions')));
    await tester.pumpAndSettle();

    expect(find.text('Activate Site'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_toggle_status_site_test_actions')));
    await tester.pumpAndSettle();

    expect(find.text('Site "Westin Gurgaon Hub" has been activated'), findsOneWidget);
    expect(SiteManager.instance.sites.firstWhere((s) => s.id == 'site_test_actions').status, 'active');

    ScaffoldMessenger.of(tester.element(find.byType(MoreModulesScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // 5. Click site card again and delete it from database
    await tester.tap(find.byKey(const Key('site_card_site_test_actions')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_delete_site_site_test_actions')));
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Delete Westin Gurgaon Hub?'), findsOneWidget);
    expect(find.text('Delete Forever'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.byKey(const Key('btn_confirm_delete_site')));
    await tester.pumpAndSettle();

    // Verify deleted
    expect(find.text('Site "Westin Gurgaon Hub" deleted from database'), findsOneWidget);
    expect(SiteManager.instance.sites.any((s) => s.id == 'site_test_actions'), isFalse);
    expect(find.text('Westin Gurgaon Hub'), findsNothing);
  });
}
