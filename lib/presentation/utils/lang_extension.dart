import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';

extension LanguageSelector on BuildContext {
  /// 3 ta tilni qabul qiladigan va unumdorlikka zarar yetkazmaydigan xavfsiz tarjima funksiyasi.
  String tr(String uz, String en, String ru) {
    // ⚡ OPTIMALLASHTIRISH: watch o'rniga read ishlatildi.
    // Bu matnlar joylashgan vidjetlarni keraksiz rebuild bo'lishidan saqlaydi.
    final lang = read<SettingsBloc>().state.locale.languageCode;

    switch (lang) {
      case 'en':
        return en;
      case 'ru':
        return ru;
      case 'uz':
      default:
        return uz;
    }
  }
}
