import 'package:flutter/material.dart';

class OnboardingAvatarCarousel extends StatefulWidget {
  final List<String> avatars;
  final ValueChanged<String> onAvatarSelected;

  const OnboardingAvatarCarousel({
    super.key,
    required this.avatars,
    required this.onAvatarSelected,
  });

  @override
  State<OnboardingAvatarCarousel> createState() =>
      _OnboardingAvatarCarouselState();
}

class _OnboardingAvatarCarouselState extends State<OnboardingAvatarCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5, initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAvatarSelected(widget.avatars[_currentIndex]);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          widget.onAvatarSelected(widget.avatars[index]);
        },
        itemCount: widget.avatars.length,
        itemBuilder: (context, index) {
          final isCenter = index == _currentIndex;

          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            scale: isCenter ? 1.2 : 0.8,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isCenter ? 1.0 : 0.4,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(
                    0.05,
                  ), // Sfondo per gli avatar trasparenti
                  border: isCenter
                      ? Border.all(color: Colors.orangeAccent, width: 3)
                      : null,
                  boxShadow: isCenter
                      ? [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.avatars[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white38,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orangeAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
