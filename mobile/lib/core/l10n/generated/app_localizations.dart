import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Application name shown in the app bar and the launcher.
  ///
  /// In tr, this message translates to:
  /// **'Yalın Üretim Asistanı'**
  String get appTitle;

  /// Button label to retry a failed operation.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get commonRetry;

  /// Shown while data is being loaded.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get commonLoading;

  /// Title of the generic error view.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get errorGenericTitle;

  /// Body of the generic error view.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı. Lütfen biraz sonra tekrar deneyin.'**
  String get errorGenericMessage;

  /// Shown when a list has no items.
  ///
  /// In tr, this message translates to:
  /// **'Burada henüz bir şey yok.'**
  String get emptyGenericMessage;

  /// Temporary message on the home page until features are added.
  ///
  /// In tr, this message translates to:
  /// **'Ekranlar yakında burada olacak.'**
  String get homeEmptyMessage;

  /// App bar title of the sign-in screen.
  ///
  /// In tr, this message translates to:
  /// **'Giriş'**
  String get loginTitle;

  /// Title shown when the user opens an unknown route.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa bulunamadı'**
  String get notFoundTitle;

  /// Message shown when the user opens an unknown route.
  ///
  /// In tr, this message translates to:
  /// **'Aradığınız sayfa mevcut değil.'**
  String get notFoundMessage;

  /// Button label that navigates to the home page.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfaya dön'**
  String get commonGoHome;

  /// Shown when the device cannot reach the server.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.'**
  String get errorNetwork;

  /// Shown on HTTP 401.
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.'**
  String get errorUnauthorized;

  /// Shown on HTTP 403.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok.'**
  String get errorForbidden;

  /// Shown on HTTP 404.
  ///
  /// In tr, this message translates to:
  /// **'Aradığınız kayıt bulunamadı.'**
  String get errorNotFound;

  /// Shown on HTTP 409 (optimistic concurrency conflict).
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt başka biri tarafından değiştirildi. Lütfen güncel hâlini kontrol edin.'**
  String get errorConflict;

  /// Shown on HTTP 400 validation errors.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen işaretli alanları kontrol edin.'**
  String get errorValidation;

  /// Title of the card on the home page that shows whether the backend is reachable.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu bağlantısı'**
  String get serverStatusTitle;

  /// Shown while the app is asking the backend for its health.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol ediliyor…'**
  String get serverStatusChecking;

  /// Shown when the backend answered Healthy.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get serverStatusOnline;

  /// Shown when the backend answered Degraded.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı, bazı servisler yavaş çalışıyor'**
  String get serverStatusDegraded;

  /// Tooltip of the button that checks the backend again.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden kontrol et'**
  String get serverStatusRefresh;

  /// Shown on the start-up screen while the stored session is checked.
  ///
  /// In tr, this message translates to:
  /// **'Oturum kontrol ediliyor…'**
  String get splashChecking;

  /// Greeting on the home page.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin, {name}'**
  String homeWelcome(String name);

  /// Tooltip of the sign-out button on the home page.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get homeSignOut;

  /// Short line under the app name on the sign-in screen.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için hesabınızla giriş yapın.'**
  String get loginSubtitle;

  /// Label of the user name field on the sign-in screen.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get loginUserName;

  /// Label of the password field on the sign-in screen.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get loginPassword;

  /// Button that signs the user in.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get loginSubmit;

  /// Shown when the server rejects the user name or password. Does not say which one was wrong.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı veya şifre hatalı.'**
  String get loginInvalidCredentials;

  /// Shown under a form field that was left empty.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunludur.'**
  String get fieldRequired;

  /// Shown on HTTP 429 (too many attempts).
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Lütfen bir dakika sonra tekrar deneyin.'**
  String get errorRateLimited;

  /// App bar title of the change-password screen.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi değiştirin'**
  String get changePasswordTitle;

  /// Explains why a user with a temporary password must change it.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızın şifresini bir yönetici belirledi. Devam etmek için kendi şifrenizi belirleyin.'**
  String get changePasswordRequiredInfo;

  /// Label of the current password field.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre'**
  String get changePasswordCurrent;

  /// Label of the new password field.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre'**
  String get changePasswordNew;

  /// Label of the field that repeats the new password.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre (tekrar)'**
  String get changePasswordConfirm;

  /// Button that changes the password.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi değiştir'**
  String get changePasswordSubmit;

  /// Shown when the new password is too short.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az {min} karakter olmalı.'**
  String changePasswordTooShort(int min);

  /// Shown when the new password equals the current one.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre mevcut şifreden farklı olmalı.'**
  String get changePasswordSameAsCurrent;

  /// Shown when the repeated new password differs.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get changePasswordMismatch;

  /// Shown when the server rejects the current password.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre hatalı.'**
  String get changePasswordWrongCurrent;

  /// Title shown when the user's role may not open a page.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfaya erişiminiz yok'**
  String get forbiddenTitle;

  /// Message shown when the user's role may not open a page.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa rolünüz için açık değil. Gerekli olduğunu düşünüyorsanız yöneticinize başvurun.'**
  String get forbiddenMessage;

  /// Shows the signed-in user's role on the home page.
  ///
  /// In tr, this message translates to:
  /// **'Rolünüz: {role}'**
  String homeRole(String role);

  /// Home page button that opens user management (admins only).
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıları yönet'**
  String get homeManageUsers;

  /// Role name. Same names as docs/business-rules.md.
  ///
  /// In tr, this message translates to:
  /// **'Operatör'**
  String get roleOperator;

  /// Role name.
  ///
  /// In tr, this message translates to:
  /// **'Şef'**
  String get roleSupervisor;

  /// Role name.
  ///
  /// In tr, this message translates to:
  /// **'Bakım Teknisyeni'**
  String get roleTechnician;

  /// Role name.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get roleManager;

  /// Role name.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// App bar title of the user management page.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get usersTitle;

  /// Placeholder until the user management screen is built.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı yönetimi bir sonraki adımda burada olacak.'**
  String get usersComingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
