import 'package:flutter/material.dart';
import 'dart:ui';

class CascadingBackground extends StatelessWidget {
  final int speed1;
  final int speed2;
  final int speed3;
  final int speed4;

  const CascadingBackground({
    super.key,
    this.speed1 = 80,
    this.speed2 = 70,
    this.speed3 = 90,
    this.speed4 = 75,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: 1.4,
            child: Transform.rotate(
              angle: -0.25,
              child: Row(
                children: [
                  Expanded(
                    child: _AutoScrollColumn(speed: speed1, isReverse: false),
                  ),
                  Expanded(
                    child: _AutoScrollColumn(speed: speed2, isReverse: true),
                  ),
                  Expanded(
                    child: _AutoScrollColumn(speed: speed3, isReverse: false),
                  ),
                  Expanded(
                    child: _AutoScrollColumn(speed: speed4, isReverse: true),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0C).withOpacity(0.8),
                    const Color(0xFF0A0A0C).withOpacity(0.4),
                    const Color(0xFF0A0A0C).withOpacity(1.0),
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoScrollColumn extends StatefulWidget {
  final int speed;
  final bool isReverse;

  const _AutoScrollColumn({required this.speed, required this.isReverse});

  @override
  State<_AutoScrollColumn> createState() => _AutoScrollColumnState();
}

class _AutoScrollColumnState extends State<_AutoScrollColumn> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted) return;

    const maxScroll = 10000.0;

    if (widget.isReverse) {
      _scrollController.jumpTo(maxScroll);
      _scrollController
          .animateTo(
            0.0,
            duration: Duration(seconds: widget.speed),
            curve: Curves.linear,
          )
          .then((_) {
            if (mounted) _startScrolling();
          });
    } else {
      _scrollController.jumpTo(0.0);
      _scrollController
          .animateTo(
            maxScroll,
            duration: Duration(seconds: widget.speed),
            curve: Curves.linear,
          )
          .then((_) {
            if (mounted) _startScrolling();
          });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1000,
      itemBuilder: (context, index) {
        final imgIndex = (index % 30) + 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: AssetImage('assets/images/covers/cover_$imgIndex.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
