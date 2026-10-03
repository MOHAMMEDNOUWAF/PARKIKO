import 'package:flutter/material.dart';
import '../../../../core/widgets/parkiko_logo.dart';

/// Top app bar with brand header, live deck status, logout action,
/// and 4 quick operational metric tiles.
class AssistantManagerAppBar extends StatelessWidget {
  final String siteName;
  final Animation<double> pulseAnimation;
  final VoidCallback onLogout;
  final int waitingCount;
  final int liveIntakesParkedCount;
  final int urgentCount;
  final int parkedCount;
  final int onDutyRunnersCount;

  const AssistantManagerAppBar({
    super.key,
    required this.siteName,
    required this.pulseAnimation,
    required this.onLogout,
    required this.waitingCount,
    required this.liveIntakesParkedCount,
    required this.urgentCount,
    required this.parkedCount,
    required this.onDutyRunnersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1FCF5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand & Site Subtitle
              Row(
                children: [
                  const ParkikoLogo(size: 32),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Parkiko',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00513A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDAE5DE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ASST. MGR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3F4944),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: Color(0xFF00513A),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            siteName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3F4944),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Status Badge & Logout Action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Deck Live Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF6EF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFBEC9C2).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF059669),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669)
                                        .withAlpha((180 * pulseAnimation.value).toInt()),
                                    blurRadius: 4 * pulseAnimation.value,
                                    spreadRadius: 1 * pulseAnimation.value,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Deck Live',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00513A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Logout Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('assistant_manager_logout_button'),
                      onTap: onLogout,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6).withAlpha(180),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFBA1A1A).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.logout_rounded,
                              size: 13,
                              color: Color(0xFFBA1A1A),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Metrics Bar (4 columns)
          Row(
            children: [
              // Metric 1: Waiting / Intake
              Expanded(
                child: _MetricTile(
                  pulseAnimation: pulseAnimation,
                  dotColor: waitingCount > 0
                      ? const Color(0xFFD97706)
                      : const Color(0xFF00513A),
                  isDotPulsing: waitingCount > 0,
                  label: 'Waiting',
                  value: waitingCount > 0
                      ? '$waitingCount Intake'
                      : (liveIntakesParkedCount > 0
                          ? '$liveIntakesParkedCount Parked'
                          : '0 Intake'),
                  valueColor: waitingCount > 0
                      ? const Color(0xFF92400E)
                      : const Color(0xFF00513A),
                ),
              ),
              const SizedBox(width: 6),

              // Metric 2: Retrievals
              Expanded(
                child: _MetricTile(
                  pulseAnimation: pulseAnimation,
                  dotColor: const Color(0xFFBA1A1A),
                  isDotPulsing: true,
                  label: 'Retrievals',
                  value: '$urgentCount Urgent',
                  valueColor: const Color(0xFFBA1A1A),
                ),
              ),
              const SizedBox(width: 6),

              // Metric 3: Parked
              Expanded(
                child: _MetricTile(
                  pulseAnimation: pulseAnimation,
                  dotColor: const Color(0xFF00513A),
                  isDotPulsing: false,
                  label: 'Parked',
                  value: '$parkedCount Ready',
                  valueColor: const Color(0xFF141E1A),
                ),
              ),
              const SizedBox(width: 6),

              // Metric 4: Runners
              Expanded(
                child: _MetricTile(
                  pulseAnimation: pulseAnimation,
                  dotColor: onDutyRunnersCount > 0
                      ? const Color(0xFF2D6955)
                      : const Color(0xFF6F7A73),
                  isDotPulsing: false,
                  label: 'Runners',
                  value: '$onDutyRunnersCount On-Duty',
                  valueColor: onDutyRunnersCount > 0
                      ? const Color(0xFF00513A)
                      : const Color(0xFF6F7A73),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Color dotColor;
  final bool isDotPulsing;
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.pulseAnimation,
    required this.dotColor,
    required this.isDotPulsing,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(100)),
      ),
      child: Row(
        children: [
          if (isDotPulsing)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withAlpha((180 * pulseAnimation.value).toInt()),
                        blurRadius: 4 * pulseAnimation.value,
                        spreadRadius: 1 * pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7A73),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
