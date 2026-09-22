import 'package:flutter/material.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/domain/sessions/session_type.dart';

/// Presents the availability and action associated with one session type.
class SessionOverviewCard extends StatelessWidget {
  final SessionOverview overview;
  final VoidCallback onPressed;

  const SessionOverviewCard({required this.overview, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(overview.sessionType);
    final hasAvailableExercises =
        overview.newExerciseCount > 0 || overview.reviewExerciseCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, presentation),
            const SizedBox(height: 24),
            _buildCounts(),
            const SizedBox(height: 20),
            _buildAction(hasAvailableExercises),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ({String title, String description, IconData icon}) presentation,
  ) {
    return Row(
      children: [
        _buildIcon(presentation.icon),
        const SizedBox(width: 14),
        Expanded(child: _buildDescription(context, presentation)),
      ],
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    ({String title, String description, IconData icon}) presentation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          presentation.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          presentation.description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF616161)),
        ),
      ],
    );
  }

  Widget _buildCounts() {
    return Row(
      children: [
        Expanded(
          child: _SessionCount(count: overview.reviewExerciseCount, label: 'To review'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SessionCount(count: overview.newExerciseCount, label: 'New'),
        ),
      ],
    );
  }

  Widget _buildAction(bool hasAvailableExercises) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: overview.hasActiveSession || hasAvailableExercises ? onPressed : null,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(overview.hasActiveSession ? 'Resume session' : 'Start new session'),
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

class _SessionCount extends StatelessWidget {
  final int count;
  final String label;

  const _SessionCount({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF616161)),
          ),
        ],
      ),
    );
  }
}
