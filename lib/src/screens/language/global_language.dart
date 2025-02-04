// global_language.dart
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

/// 言語設定用の enum
// ignore: constant_identifier_names
enum Language { Japanese, English }

/// 現在の言語設定（初期値は日本語）
Language selectedLanguage = Language.Japanese;

/// translator のグローバルインスタンス
final GoogleTranslator globalTranslator = GoogleTranslator();

/// 翻訳表示用ウィジェット
/// ・selectedLanguage が English の場合、translator を使って原文を英語に翻訳して表示
/// ・日本語の場合は原文をそのまま表示
class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedLanguage == Language.Japanese) {
      return Text(text, style: style, textAlign: textAlign);
    } else {
      return FutureBuilder(
        future: globalTranslator.translate(text, to: 'en'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 翻訳中は原文を表示
            return Text(text, style: style, textAlign: textAlign);
          }
          if (snapshot.hasError) {
            // エラー時は原文を表示
            return Text(text, style: style, textAlign: textAlign);
          }
          // translator パッケージでは Translation 型が返る
          final translation = snapshot.data;
          return Text(
            translation?.text ?? text,
            style: style,
            textAlign: textAlign,
          );
        },
      );
    }
  }
}