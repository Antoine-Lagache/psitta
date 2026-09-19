import 'package:flutter/material.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/ui/screens/home/session_overview_card.dart';

/// Displays the successfully loaded content of the home screen.
class HomeContent extends StatelessWidget {
  final List<SessionOverview> overviews;
  final RefreshCallback onRefresh;
  final ValueChanged<SessionOverview> onSessionSelected;

  const HomeContent({
    required this.overviews,
    required this.onRefresh,
    required this.onSessionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: [
              Text(
                'Choose a session',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review what is due or start learning something new.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 28),
              for (var index = 0; index < overviews.length; index++) ...[
                SessionOverviewCard(
                  overview: overviews[index],
                  onPressed: () => onSessionSelected(overviews[index]),
                ),
                if (index < overviews.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
