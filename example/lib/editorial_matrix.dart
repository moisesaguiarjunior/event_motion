import 'package:fluvie/fluvie.dart' as video;
import 'package:flutter/widgets.dart';

import 'src/matrix_document.dart';

const _paper = Color(0xFFF7F5EF);
const _ink = Color(0xFF202A32);
const _muted = Color(0xFF465865);
const _rule = Color(0xFFB9C0BF);
const _blue = Color(0xFF124B73);
const _amber = Color(0xFF784108);
const _cloudPaper = Color(0xFFEAF0F2);
const _operatorPaper = Color(0xFFF3E9D8);

video.Video build(MatrixDocument document) => video.Video(
  width: document.heroStat == null ? 1440 : 1080,
  height: document.heroStat == null ? 1800 : 1350,
  fps: 24,
  poster: video.Time.frames(0),
  scenes: [
    video.Scene(
      duration: video.Time.frames(1),
      children: [
        Positioned.fill(
          child: FittedBox(
            child: SizedBox(width: 480, height: 600, child: _Matrix(document)),
          ),
        ),
      ],
    ),
  ],
);

class _Matrix extends StatelessWidget {
  const _Matrix(this.document);

  final MatrixDocument document;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 3, child: ColoredBox(color: _ink)),
          const SizedBox(height: 12),
          _copy(document.title, size: 30, weight: FontWeight.w700),
          if (document.heroStat case final stat?) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _copy(
                  stat.value,
                  size: 54,
                  weight: FontWeight.w800,
                  color: _blue,
                ),
              ),
            ),
            _copy(stat.caption, size: 15, weight: FontWeight.w600),
          ],
          const SizedBox(height: 13),
          _line([
            for (final (index, title) in document.columns.indexed)
              _copy(
                title,
                color: index == 2
                    ? _blue
                    : index == 3
                    ? _amber
                    : _ink,
                weight: FontWeight.w700,
              ),
          ]),
          for (final row in document.rows) ...[
            const SizedBox(height: 1, child: ColoredBox(color: _rule)),
            Expanded(
              flex: row.cloud.length > 80 || row.operator.length > 80 ? 12 : 9,
              child: _line([
                _copy(
                  row.date.replaceAll('-', '\u2011'),
                  size: 11.5,
                  color: _muted,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _copy(row.change, size: 12, weight: FontWeight.w700),
                    const SizedBox(height: 5),
                    _copy(
                      row.sourceIds.map((id) => '[$id]').join(' '),
                      size: 11,
                      color: _muted,
                    ),
                  ],
                ),
                _copy(row.cloud, size: 12, color: _blue),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _copy(row.operator, size: 12, color: _amber),
                    if (row.operatorCloud case final note?) ...[
                      const SizedBox(height: 4),
                      _copy(note, size: 12, color: _blue),
                    ],
                  ],
                ),
              ], body: true),
            ),
          ],
          const SizedBox(height: 2, child: ColoredBox(color: _ink)),
          const SizedBox(height: 9),
          _copy(document.footer, size: 13, weight: FontWeight.w700),
          const SizedBox(height: 5),
          Wrap(
            spacing: 10,
            runSpacing: 3,
            children: [
              for (final source in document.sources.entries)
                _copy(
                  '[${source.key}] ${source.value}',
                  size: 12,
                  color: _muted,
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _line(List<Widget> cells, {bool body = false}) {
    const widths = [18, 25, 28, 29];
    return Row(
      crossAxisAlignment: body
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        for (final (index, cell) in cells.indexed)
          Expanded(
            flex: widths[index],
            child: ColoredBox(
              color: index == 2
                  ? _cloudPaper
                  : index == 3
                  ? _operatorPaper
                  : _paper,
              child: Padding(
                padding: EdgeInsets.fromLTRB(index == 0 ? 0 : 8, 4, 5, 4),
                child: body
                    ? LayoutBuilder(
                        builder: (context, bounds) => FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: bounds.maxWidth, child: cell),
                        ),
                      )
                    : Align(alignment: Alignment.centerLeft, child: cell),
              ),
            ),
          ),
      ],
    );
  }
}

Text _copy(
  String text, {
  double size = 15,
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
}) => Text(
  text,
  style: TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    color: color,
    height: 1.13,
    fontWeight: weight,
  ),
);
