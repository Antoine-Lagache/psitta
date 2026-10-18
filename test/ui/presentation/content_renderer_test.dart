import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/presentation/content/field_renderer.dart';

class _HtmlFields implements FieldRenderer {
  @override
  Future<String> render(Field field) async => (field.value as TextFieldValue).value;
}

void main() {
  testWidgets('Japanese ruby uses bundled font and fits a narrow scaled card', (
    tester,
  ) async {
    final fonts = FontLoader('NotoSansJP')
      ..addFont(rootBundle.load('assets/fonts/NotoSansJP-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansJP-Bold.otf'));
    await fonts.load();
    final content = Content(
      id: 1,
      fields: [
        Field(
          id: 1,
          definition: FieldDefinition(
            id: 1,
            valueType: FieldValueType.html,
            side: FieldSide.back,
          ),
          value: TextFieldValue(
            '<div style="font-size:24px;line-height:1.5">'
            '<ruby>再来月<rt>さらいげつ</rt></ruby>に行きます。</div>'
            '<div style="font-size:19px">I will go the month after next.</div>'
            '<div style="font-size:12px">Source: Tatoeba</div>',
          ),
          displayOrder: 0,
        ),
      ],
    );
    final card = await ContentRenderer(_HtmlFields()).render(content, FieldSide.back);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: 240, child: SingleChildScrollView(child: card)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final runs = <String, TextStyle>{};
    void collect(InlineSpan span, TextStyle inherited) {
      if (span is TextSpan) {
        final style = inherited.merge(span.style);
        if (span.text != null) runs[span.text!] = style;
        for (final child in span.children ?? <InlineSpan>[]) {
          collect(child, style);
        }
      }
    }

    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      collect(rich.text, const TextStyle());
    }
    final japanese = runs.entries.firstWhere((e) => e.key.contains('再来月')).value;
    expect(japanese.fontFamily, 'NotoSansJP');
    expect(japanese.fontWeight, FontWeight.w500);
    expect(japanese.fontSize, 29);
    expect(runs['Source: Tatoeba']?.fontSize, 12);
    expect(runs['I will go the month after next.']?.fontSize, 19);
    expect(runs.keys.any((text) => text.contains('さらいげつ')), isTrue);
  });
}
