// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yalın Üretim Asistanı';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get errorGenericTitle => 'Bir şeyler ters gitti';

  @override
  String get errorGenericMessage =>
      'İşlem tamamlanamadı. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get emptyGenericMessage => 'Burada henüz bir şey yok.';

  @override
  String get homeEmptyMessage => 'Ekranlar yakında burada olacak.';

  @override
  String get loginTitle => 'Giriş';

  @override
  String get notFoundTitle => 'Sayfa bulunamadı';

  @override
  String get notFoundMessage => 'Aradığınız sayfa mevcut değil.';

  @override
  String get commonGoHome => 'Ana sayfaya dön';

  @override
  String get errorNetwork =>
      'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.';

  @override
  String get errorUnauthorized =>
      'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get errorForbidden => 'Bu işlem için yetkiniz yok.';

  @override
  String get errorNotFound => 'Aradığınız kayıt bulunamadı.';

  @override
  String get errorConflict =>
      'Bu kayıt başka biri tarafından değiştirildi. Lütfen güncel hâlini kontrol edin.';

  @override
  String get errorValidation => 'Lütfen işaretli alanları kontrol edin.';

  @override
  String get serverStatusTitle => 'Sunucu bağlantısı';

  @override
  String get serverStatusChecking => 'Kontrol ediliyor…';

  @override
  String get serverStatusOnline => 'Bağlı';

  @override
  String get serverStatusDegraded => 'Bağlı, bazı servisler yavaş çalışıyor';

  @override
  String get serverStatusRefresh => 'Yeniden kontrol et';

  @override
  String get splashChecking => 'Oturum kontrol ediliyor…';

  @override
  String homeWelcome(String name) {
    return 'Hoş geldin, $name';
  }

  @override
  String get homeSignOut => 'Çıkış yap';

  @override
  String get loginSubtitle => 'Devam etmek için hesabınızla giriş yapın.';

  @override
  String get loginUserName => 'Kullanıcı adı';

  @override
  String get loginPassword => 'Şifre';

  @override
  String get loginSubmit => 'Giriş yap';

  @override
  String get loginInvalidCredentials => 'Kullanıcı adı veya şifre hatalı.';

  @override
  String get fieldRequired => 'Bu alan zorunludur.';

  @override
  String get errorRateLimited =>
      'Çok fazla deneme yapıldı. Lütfen bir dakika sonra tekrar deneyin.';

  @override
  String get changePasswordTitle => 'Şifrenizi değiştirin';

  @override
  String get changePasswordRequiredInfo =>
      'Hesabınızın şifresini bir yönetici belirledi. Devam etmek için kendi şifrenizi belirleyin.';

  @override
  String get changePasswordCurrent => 'Mevcut şifre';

  @override
  String get changePasswordNew => 'Yeni şifre';

  @override
  String get changePasswordConfirm => 'Yeni şifre (tekrar)';

  @override
  String get changePasswordSubmit => 'Şifreyi değiştir';

  @override
  String changePasswordTooShort(int min) {
    return 'Şifre en az $min karakter olmalı.';
  }

  @override
  String get changePasswordSameAsCurrent =>
      'Yeni şifre mevcut şifreden farklı olmalı.';

  @override
  String get changePasswordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get changePasswordWrongCurrent => 'Mevcut şifre hatalı.';

  @override
  String get forbiddenTitle => 'Bu sayfaya erişiminiz yok';

  @override
  String get forbiddenMessage =>
      'Bu sayfa rolünüz için açık değil. Gerekli olduğunu düşünüyorsanız yöneticinize başvurun.';

  @override
  String homeRole(String role) {
    return 'Rolünüz: $role';
  }

  @override
  String get homeManageUsers => 'Kullanıcıları yönet';

  @override
  String get roleOperator => 'Operatör';

  @override
  String get roleSupervisor => 'Şef';

  @override
  String get roleTechnician => 'Bakım Teknisyeni';

  @override
  String get roleManager => 'Yönetici';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get usersTitle => 'Kullanıcılar';

  @override
  String get usersComingSoon =>
      'Kullanıcı yönetimi bir sonraki adımda burada olacak.';
}
