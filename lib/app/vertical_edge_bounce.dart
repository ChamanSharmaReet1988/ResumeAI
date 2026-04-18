import 'package:flutter/material.dart';

/// Overscroll bounce on the vertical axis only (top/bottom). Horizontal
/// scrollables use [ClampingScrollPhysics] so there is no left/right bounce.
class AxisVerticalBouncePhysics extends ScrollPhysics {
  const AxisVerticalBouncePhysics({super.parent});

  @override
  AxisVerticalBouncePhysics applyTo(ScrollPhysics? ancestor) {
    return AxisVerticalBouncePhysics(parent: buildParent(ancestor));
  }

  ScrollPhysics _pick(ScrollMetrics position) {
    return position.axis == Axis.vertical
        ? BouncingScrollPhysics(parent: parent)
        : ClampingScrollPhysics(parent: parent);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return _pick(position).applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return _pick(position).applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return _pick(position).createBallisticSimulation(position, velocity);
  }
}

/// App-wide: vertical lists/pages bounce at top/bottom; horizontal scrolls clamp.
class VerticalEdgeBounceScrollBehavior extends MaterialScrollBehavior {
  const VerticalEdgeBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return AxisVerticalBouncePhysics(parent: super.getScrollPhysics(context));
  }
}
