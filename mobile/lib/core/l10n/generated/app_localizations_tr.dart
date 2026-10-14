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
  String get homeGoToLogin => 'Giriş ekranını aç';

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
}
