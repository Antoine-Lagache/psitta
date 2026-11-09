import 'package:flutter/material.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/ui/screens/home/session_overview_card.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/ui/presentation/info_button.dart';

/// Displays the successfully loaded content of the home screen.
class HomeContent extends StatelessWidget {
  final List<SessionOverview> overviews;
  final bool loadingCharacters;
  final bool characterLoadFailed;
  final RefreshCallback onRefresh;
  final ValueChanged<SessionOverview> onSessionSelected;
  final ValueChanged<SessionOverview> onSessionAbandon;

  const HomeContent({
    required this.overviews,
    this.loadingCharacters = false,
    this.characterLoadFailed = false,
    required this.onRefresh,
    required this.onSessionSelected,
    required this.onSessionAbandon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildScrollableContent(context),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            ..._buildHeader(context),
            const SizedBox(height: 28),
            ..._buildSessionCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeader(BuildContext context) {
    return [
      Text(
        'Choose a session',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 4),
      const InfoButton(
        label: 'Daily recommendation',
        title: 'A balanced daily routine',
        message:
            'Try to complete one Words session and one Sentences session each day. Words build vocabulary through individual items; Sentences help you recognize vocabulary in context. Sessions can include due reviews and new exercises, depending on what is available. You can pause a session and resume it later. This is a flexible guideline, not a daily requirement.',
      ),
    ];
  }

  List<Widget> _buildSessionCards() {
    final orderedOverviews = [...overviews]
      ..sort(
        (first, second) => _displayOrder(first.sessionType).compareTo(
          _displayOrder(second.sessionType),
        ),
      );

    return [
      for (var index = 0; index < orderedOverviews.length; index++) ...[
        SessionOverviewCard(
          overview: orderedOverviews[index],
          isLoading:
              loadingCharacters &&
              orderedOverviews[index].sessionType ==
                  SessionType.characterSession,
          loadFailed:
              characterLoadFailed &&
              orderedOverviews[index].sessionType ==
                  SessionType.characterSession,
          onPressed: () => onSessionSelected(orderedOverviews[index]),
          onAbandon: orderedOverviews[index].hasActiveSession
              ? () => onSessionAbandon(orderedOverviews[index])
              : null,
        ),
        if (index < orderedOverviews.length - 1) const SizedBox(height: 16),
      ],
    ];
  }

  int _displayOrder(SessionType type) => switch (type) {
    SessionType.characterSession => 0,
    SessionType.wordSession => 1,
    SessionType.sentenceSession => 2,
  };
}
