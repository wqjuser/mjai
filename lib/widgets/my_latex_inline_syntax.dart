import 'package:markdown/markdown.dart' as md;

class MyLatexInlineSyntax extends md.InlineSyntax {
  MyLatexInlineSyntax() : super(r'(\$\$[^\$]*\$\$)|(\$[^\$]+\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    String matchText = match.group(0)!;
    parser.addNode(md.Element.text('latex', matchText));
    return true;
  }
}