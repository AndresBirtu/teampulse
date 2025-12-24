import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:teampulse/features/players/constants/injury_areas.dart';

class InjuryBodySelector extends StatelessWidget {
  const InjuryBodySelector({
    super.key,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  final String? selectedArea;
  final ValueChanged<String> onAreaSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona la zona lesionada',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BodySilhouettePainter(theme.colorScheme.primary.withOpacity(0.15)),
                    ),
                  ),
                  for (final area in _bodyAreas)
                    Positioned(
                      left: area.rect.left * width,
                      top: area.rect.top * height,
                      width: area.rect.width * width,
                      height: area.rect.height * height,
                      child: GestureDetector(
                        onTap: () => onAreaSelected(area.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: area.id == selectedArea
                                ? Colors.red.withOpacity(0.35)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: area.id == selectedArea ? Colors.red : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: area.id == selectedArea ? Colors.white : Colors.black26,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bodyAreas
              .map(
                (area) => ChoiceChip(
                  label: Text(kInjuryAreaLabels[area.id] ?? area.id),
                  selected: area.id == selectedArea,
                  onSelected: (_) => onAreaSelected(area.id),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(
          selectedArea == null
              ? 'Toca una zona del monigote para continuar.'
              : 'Zona seleccionada: ${describeInjuryArea(selectedArea)}',
          style: TextStyle(
            fontSize: 12,
            color: selectedArea == null ? Colors.grey : Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}

class _BodyAreaDefinition {
  const _BodyAreaDefinition({required this.id, required this.rect});

  final String id;
  final Rect rect;
}

final List<_BodyAreaDefinition> _bodyAreas = [
  _BodyAreaDefinition(id: 'head', rect: Rect.fromLTWH(0.37, 0.0, 0.26, 0.18)),
  _BodyAreaDefinition(id: 'neck', rect: Rect.fromLTWH(0.42, 0.17, 0.16, 0.05)),
  _BodyAreaDefinition(id: 'chest', rect: Rect.fromLTWH(0.33, 0.22, 0.34, 0.18)),
  _BodyAreaDefinition(id: 'abdomen', rect: Rect.fromLTWH(0.33, 0.40, 0.34, 0.12)),
  _BodyAreaDefinition(id: 'shoulder', rect: Rect.fromLTWH(0.2, 0.22, 0.60, 0.1)),
  _BodyAreaDefinition(id: 'arm', rect: Rect.fromLTWH(0.12, 0.34, 0.77, 0.09)),
  _BodyAreaDefinition(id: 'hand', rect: Rect.fromLTWH(0.05, 0.41, 0.90, 0.09)),
  _BodyAreaDefinition(id: 'hip', rect: Rect.fromLTWH(0.33, 0.52, 0.34, 0.08)),
  _BodyAreaDefinition(id: 'thigh', rect: Rect.fromLTWH(0.33, 0.60, 0.34, 0.13)),
  _BodyAreaDefinition(id: 'knee', rect: Rect.fromLTWH(0.35, 0.73, 0.30, 0.07)),
  _BodyAreaDefinition(id: 'leg', rect: Rect.fromLTWH(0.36, 0.80, 0.28, 0.09)),
  _BodyAreaDefinition(id: 'ankle', rect: Rect.fromLTWH(0.36, 0.89, 0.28, 0.04)),
  _BodyAreaDefinition(id: 'foot', rect: Rect.fromLTWH(0.32, 0.93, 0.36, 0.05)),
];

class _BodySilhouettePainter extends CustomPainter {
  _BodySilhouettePainter(this.fillColor);

  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Head
    final headRadius = size.width * 0.14;
    final headCenter = Offset(centerX, size.height * 0.12);
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, outline);

    final torsoTop = headCenter.dy + headRadius * 0.9;
    final torsoBottom = size.height * 0.58;
    final shoulderWidth = size.width * 0.55;
    final waistWidth = size.width * 0.30;
    final hipWidth = size.width * 0.38;

    final torsoPath = Path()
      ..moveTo(centerX - shoulderWidth / 2, torsoTop)
      ..quadraticBezierTo(
        centerX - shoulderWidth / 2,
        torsoTop + 12,
        centerX - waistWidth / 2,
        torsoTop + 55,
      )
      ..quadraticBezierTo(
        centerX - hipWidth / 2,
        torsoBottom - 10,
        centerX - hipWidth / 2,
        torsoBottom,
      )
      ..lineTo(centerX + hipWidth / 2, torsoBottom)
      ..quadraticBezierTo(
        centerX + hipWidth / 2,
        torsoBottom - 10,
        centerX + waistWidth / 2,
        torsoTop + 55,
      )
      ..quadraticBezierTo(
        centerX + shoulderWidth / 2,
        torsoTop + 12,
        centerX + shoulderWidth / 2,
        torsoTop,
      )
      ..close();
    canvas.drawPath(torsoPath, fill);
    canvas.drawPath(torsoPath, outline);

    final armWidth = size.width * 0.12;
    final armLength = size.height * 0.35;
    final armRadius = Radius.circular(armWidth);

    final leftArmRect = Rect.fromLTWH(
      centerX - shoulderWidth / 2 - armWidth * 0.9,
      torsoTop + 10,
      armWidth,
      armLength,
    );
    final rightArmRect = Rect.fromLTWH(
      centerX + shoulderWidth / 2 - armWidth * 0.1,
      torsoTop + 10,
      armWidth,
      armLength,
    );
    final leftArm = RRect.fromRectAndRadius(leftArmRect, armRadius);
    final rightArm = RRect.fromRectAndRadius(rightArmRect, armRadius);
    canvas.drawRRect(leftArm, fill);
    canvas.drawRRect(rightArm, fill);
    canvas.drawRRect(leftArm, outline);
    canvas.drawRRect(rightArm, outline);

    final legWidth = size.width * 0.16;
    final legLength = size.height * 0.35;
    final gap = size.width * 0.04;
    final legsTop = torsoBottom;
    final leftLegRect = Rect.fromLTWH(
      centerX - legWidth - gap / 2,
      legsTop,
      legWidth,
      legLength,
    );
    final rightLegRect = Rect.fromLTWH(
      centerX + gap / 2,
      legsTop,
      legWidth,
      legLength,
    );
    final legRadius = Radius.circular(legWidth * 0.4);
    final leftLeg = RRect.fromRectAndRadius(leftLegRect, legRadius);
    final rightLeg = RRect.fromRectAndRadius(rightLegRect, legRadius);
    canvas.drawRRect(leftLeg, fill);
    canvas.drawRRect(rightLeg, fill);
    canvas.drawRRect(leftLeg, outline);
    canvas.drawRRect(rightLeg, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
