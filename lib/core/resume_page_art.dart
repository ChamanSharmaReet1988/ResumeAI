import 'dart:math' as math;

/// Page art shared by the PDF pages and their on-screen previews, so both draw
/// the same shapes. Coordinates are A4 points with the origin at the top left;
/// the PDF painters flip y. Every [tint] blends white toward the accent color
/// (0 = white, 1 = accent), so the art follows the color sheet.
const double kResumePageWidthPt = 595.28;
const double kResumePageHeightPt = 841.89;

class PageArtFacet {
  const PageArtFacet(this.points, {this.tint = 1, this.neutralArgb});

  final List<(double, double)> points;
  final double tint;

  /// Fixed stone color; when set, [tint] is ignored.
  final int? neutralArgb;
}

class PageArtDot {
  const PageArtDot(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class PageArtRing {
  const PageArtRing(this.x, this.y, this.radius, {required this.tint, this.fill = false});

  final double x;
  final double y;
  final double radius;
  final double tint;
  final bool fill;
}

const int _terrazzoSand = 0xFFE6D5C3;
const int _terrazzoStone = 0xFFB9AEA3;

/// Terrazzo: chips in the top corner (above the body) and along the foot.
const List<PageArtFacet> kTerrazzoCornerChips = [
  PageArtFacet([(452, 8), (478, 3), (486, 22), (461, 30)], tint: 0.5),
  PageArtFacet([(500, 12), (528, 6), (522, 32), (503, 30)], neutralArgb: _terrazzoSand),
  PageArtFacet([(542, 4), (574, 12), (566, 36), (540, 28)], tint: 0.85),
  PageArtFacet([(428, 34), (444, 30), (450, 46), (432, 50)], neutralArgb: _terrazzoStone),
  PageArtFacet([(470, 42), (498, 38), (502, 62), (476, 68)], neutralArgb: _terrazzoSand),
  PageArtFacet([(518, 44), (536, 40), (544, 60), (522, 66)], tint: 0.3),
  PageArtFacet([(556, 48), (588, 44), (590, 74), (562, 80)], tint: 0.55),
  PageArtFacet([(506, 76), (530, 72), (538, 92), (512, 98)], tint: 0.85),
  PageArtFacet([(460, 80), (476, 76), (482, 92), (464, 96)], tint: 0.3),
  PageArtFacet([(552, 90), (572, 88), (576, 106), (556, 110)], neutralArgb: _terrazzoStone),
];

const List<PageArtFacet> kTerrazzoFootChips = [
  PageArtFacet([(18, 816), (44, 812), (50, 834), (24, 838)], tint: 0.55),
  PageArtFacet([(66, 820), (86, 816), (92, 832), (70, 836)], neutralArgb: _terrazzoSand),
  PageArtFacet([(112, 814), (134, 818), (128, 836), (108, 834)], tint: 0.85),
  PageArtFacet([(158, 822), (172, 818), (178, 832), (162, 836)], neutralArgb: _terrazzoStone),
  PageArtFacet([(204, 816), (232, 814), (234, 834), (208, 838)], tint: 0.3),
  PageArtFacet([(262, 820), (280, 816), (286, 834), (264, 836)], tint: 0.55),
  PageArtFacet([(310, 814), (332, 818), (328, 836), (306, 834)], neutralArgb: _terrazzoSand),
  PageArtFacet([(358, 822), (374, 818), (380, 834), (362, 836)], tint: 0.85),
  PageArtFacet([(404, 816), (432, 814), (436, 834), (408, 838)], neutralArgb: _terrazzoStone),
  PageArtFacet([(460, 820), (478, 816), (484, 832), (462, 836)], tint: 0.3),
  PageArtFacet([(508, 814), (532, 818), (526, 836), (504, 834)], tint: 0.55),
  PageArtFacet([(552, 820), (578, 816), (582, 834), (556, 838)], neutralArgb: _terrazzoSand),
];

/// Prism: shards fanned out from the top corner, and a bar along the foot.
const List<PageArtFacet> kPrismCornerFacets = [
  PageArtFacet([(430, 0), (510, 0), (540, 48)], tint: 0.18),
  PageArtFacet([(510, 0), (kResumePageWidthPt, 0), (540, 48)], tint: 0.5),
  PageArtFacet([(kResumePageWidthPt, 0), (kResumePageWidthPt, 60), (540, 48)], tint: 1),
  PageArtFacet([(kResumePageWidthPt, 60), (kResumePageWidthPt, 118), (540, 48)], tint: 0.34),
];

const List<PageArtFacet> kPrismFootFacets = [
  PageArtFacet([
    (0, kResumePageHeightPt - 8),
    (kResumePageWidthPt, kResumePageHeightPt - 8),
    (kResumePageWidthPt, kResumePageHeightPt),
    (0, kResumePageHeightPt),
  ]),
  PageArtFacet([
    (0, kResumePageHeightPt - 8),
    (30, kResumePageHeightPt - 8),
    (0, kResumePageHeightPt - 40),
  ], tint: 0.4),
];

/// Orbit: rings around the top corner with a satellite on the middle ring.
const List<PageArtRing> kOrbitCornerRings = [
  PageArtRing(kResumePageWidthPt, 0, 116, tint: 0.2),
  PageArtRing(kResumePageWidthPt, 0, 84, tint: 0.32),
  PageArtRing(kResumePageWidthPt, 0, 52, tint: 0.45),
  PageArtRing(kResumePageWidthPt, 0, 26, tint: 0.9, fill: true),
  PageArtRing(kResumePageWidthPt - 59.4, 59.4, 5, tint: 0.9, fill: true),
];

const List<PageArtRing> kOrbitFootRings = [
  PageArtRing(0, kResumePageHeightPt, 34, tint: 0.3),
  PageArtRing(0, kResumePageHeightPt, 14, tint: 0.7, fill: true),
];

/// Vertex: the angled header on the first page, height in points at each edge.
const double kVertexWedgeLeftPt = 172;
const double kVertexWedgeRightPt = 128;
const double kVertexSliverPt = 8;

const List<PageArtFacet> kVertexWedgeFacets = [
  PageArtFacet([
    (0, 0),
    (kResumePageWidthPt, 0),
    (kResumePageWidthPt, kVertexWedgeRightPt),
    (0, kVertexWedgeLeftPt),
  ]),
  PageArtFacet([
    (0, kVertexWedgeLeftPt),
    (kResumePageWidthPt, kVertexWedgeRightPt),
    (kResumePageWidthPt, kVertexWedgeRightPt + kVertexSliverPt),
    (0, kVertexWedgeLeftPt + kVertexSliverPt),
  ], tint: 0.3),
];

/// Dotfield: a halftone grid that shrinks away from the top corner, plus a low
/// band of dots under the body along the foot.
final List<PageArtDot> kDotfieldDots = List.unmodifiable(_buildDotfield());

List<PageArtDot> _buildDotfield() {
  const pitch = 13.0;
  const cornerWidth = 190.0;
  const cornerHeight = 112.0;
  final dots = <PageArtDot>[];
  for (var y = 6.0; y < cornerHeight; y += pitch) {
    for (var x = kResumePageWidthPt - 6; x > kResumePageWidthPt - cornerWidth; x -= pitch) {
      final dx = (kResumePageWidthPt - x) / cornerWidth;
      final dy = y / cornerHeight;
      final radius = 3.4 * (1 - math.sqrt(dx * dx + dy * dy));
      if (radius >= 0.5) dots.add(PageArtDot(x, y, radius));
    }
  }
  const footHeight = 30.0;
  for (var y = kResumePageHeightPt - 6; y > kResumePageHeightPt - footHeight; y -= pitch) {
    for (var x = 6.0; x < 170; x += pitch) {
      final dx = x / 170;
      final dy = (kResumePageHeightPt - y) / footHeight;
      final radius = 2.8 * (1 - math.sqrt(dx * dx + dy * dy));
      if (radius >= 0.5) dots.add(PageArtDot(x, y, radius));
    }
  }
  return dots;
}

/// Summit: colored band and contact strip on the first page.
const double kSummitBandPt = 122;
const double kSummitStripPt = 32;
const double kSummitPageTopPt = 30;
const double kSummitPhotoPt = 84;

/// Folio: width of the section label margin and the gap beside it.
const double kFolioLabelPt = 112;
const double kFolioGutterPt = 14;
const double kFolioPhotoPt = 74;

/// Beacon: tinted rail along the right edge of the page.
const double kBeaconRailPt = 196;
const double kBeaconRailInsetPt = 16;
const double kBeaconPhotoPt = 96;

/// Vertex: side column to the right of the body, under the angled header.
const double kVertexSidePt = 170;
const double kVertexPhotoPt = 92;
const double kVertexBodyTopPt = 192;

/// Space between the main column and a rail or side column.
const double kProfessionalColumnGapPt = 22;
const double kProfessionalPageSidePt = 34;
const double kProfessionalPageTopPt = 34;
const double kProfessionalPageBottomPt = 36;
