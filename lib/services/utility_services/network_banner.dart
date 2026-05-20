import 'dart:ui';
import 'package:flutter/material.dart';
import '../../injection_container.dart';
import 'network_status_service.dart';

class GlobalNetworkBanner extends StatefulWidget {
  final Widget child;

  const GlobalNetworkBanner({super.key, required this.child});

  @override
  State<GlobalNetworkBanner> createState() => _GlobalNetworkBannerState();
}

class _GlobalNetworkBannerState extends State<GlobalNetworkBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late bool _wasOffline;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _wasOffline = !sl<NetworkStatusService>().isOnline;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        ListenableBuilder(
          listenable: sl<NetworkStatusService>(),
          builder: (context, _) {
            final svc = sl<NetworkStatusService>();
            final isOffline = !svc.isOnline;
            final hasResolved = svc.hasResolvedInitialStatus;

            // Se torna online, reset dismissed così se va offline di nuovo ricompare
            if (_wasOffline && !isOffline) {
              _dismissed = false;
            }
            _wasOffline = isOffline;

            final showBanner = hasResolved && isOffline && !_dismissed;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              top: showBanner ? 0 : -120,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          // Nero pece quasi puro con leggera traslucenza
                          color: const Color(0xFF080809).withOpacity(0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 30,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Icona con pulse
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _pulseAnim.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C00).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.wifi_off_rounded,
                                    color: Color(0xFFFF8C00),
                                    size: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Testo
                              const Expanded(
                                child: Text(
                                  'Sei offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              // Pulsante chiudi
                              GestureDetector(
                                onTap: () => setState(() => _dismissed = true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
