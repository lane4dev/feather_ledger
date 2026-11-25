import 'package:flutter/material.dart';

/// Scaffold whose app bar takes a shallow container tint once the page scrolls
/// under it.
///
/// The budget tabs keep a flat, surface-coloured app bar at rest. Material's
/// own `scrolledUnderElevation` overlay is invisible here because the theme
/// tints with `surface`, so the tint is derived from the scroll position and
/// painted by the caller through [appBarBuilder].
class ScrolledTintScaffold extends StatefulWidget {
  final PreferredSizeWidget Function(
    BuildContext context,
    bool scrolledUnder,
  ) appBarBuilder;
  final Widget body;

  const ScrolledTintScaffold({
    super.key,
    required this.appBarBuilder,
    required this.body,
  });

  @override
  State<ScrolledTintScaffold> createState() => _ScrolledTintScaffoldState();
}

class _ScrolledTintScaffoldState extends State<ScrolledTintScaffold> {
  bool _scrolledUnder = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final next = notification.metrics.pixels > 0.5;
    if (next != _scrolledUnder) {
      setState(() => _scrolledUnder = next);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBarBuilder(context, _scrolledUnder),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.body,
      ),
    );
  }
}
