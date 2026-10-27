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
  String get loginComingSoon => 'Giriş ekranı yakında burada olacak.';

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
}
