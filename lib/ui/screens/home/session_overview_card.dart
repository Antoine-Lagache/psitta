import 'package:flutter/material.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/domain/sessions/session_type.dart';

/// Presents the availability and action associated with one session type.
class SessionOverviewCard extends StatelessWidget {
  final SessionOverview overview;
  final VoidCallback onPressed;

  const SessionOverviewCard({
    required this.overview,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(overview.sessionType);
    final canStart =
        overview.hasActiveSession ||
        overview.newExerciseCount + overview.reviewExerciseCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(presentation.icon, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        presentation.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCount(
                    context,
                    count: overview.reviewExerciseCount,
                    label: 'To review',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCount(
                    context,
                    count: overview.newExerciseCount,
                    label: 'New',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canStart ? onPressed : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  overview.hasActiveSession
                      ? 'Resume session'
                      : 'Start new session',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCount(
    BuildContext context, {
    required int count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  ({String title, String description, IconData icon}) _presentationFor(
    SessionType sessionType,
  ) {
    return switch (sessionType) {
      SessionType.wordSession => (
        title: 'Words',
        description: 'Build and review your vocabulary',
        icon: Icons.translate,
      ),
      SessionType.sentenceSession => (
        title: 'Sentences',
        description: 'Practice words in context',
        icon: Icons.notes,
      ),
    };
  }
}
