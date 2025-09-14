import 'package:flutter/material.dart';

class HerbicideGuidePage extends StatelessWidget {
  const HerbicideGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weed Control Guide'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDisclaimerCard(textTheme),
          const SizedBox(height: 20),
          _buildSectionHeader(context, Icons.energy_savings_leaf, 'Early Stage (Up to 25 Days)'),
          _buildEarlyStageCard(textTheme, context),
          const SizedBox(height: 20),
          _buildSectionHeader(context, Icons.eco, 'Mature Stage (After 30 Days)'),
          _buildMatureStageCard(textTheme, context),
          const SizedBox(height: 20),
          _buildSectionHeader(context, Icons.health_and_safety, 'Key Ratios & Safety'),
          _buildSafetyCard(textTheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDisclaimerCard(TextTheme textTheme) {
    return Card(
      elevation: 2,
      color: Colors.yellow.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
            const SizedBox(height: 8),
            Text(
              "Important Disclaimer",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Herbicide type and dosage depend on local regulations, weed types, and specific product labels. Always read and follow the manufacturer's instructions. Consult a local agricultural expert for advice tailored to your farm.",
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyStageCard(TextTheme textTheme, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pre-emergence herbicides are most effective at this stage as the crop is small and sensitive. Apply right after transplanting but before weeds germinate.",
              style: textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            _buildRichTextInfo(
              context,
              'Pendimethalin 30% EC:',
              '1.0–1.5 L/acre',
              ' (2.5–3.5 L/ha) mixed in 200–250 L of water.',
            ),
            const SizedBox(height: 16),
            _buildRichTextInfo(
              context,
              'Oxyfluorfen 23.5% EC:',
              '150–200 ml/acre',
              ' (350–500 ml/ha), also applied as pre-emergence.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatureStageCard(TextTheme textTheme, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The crop canopy is stronger, so selective post-emergence herbicides can be used if weeds appear. Never spray non-selective herbicides over the crop.",
              style: textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            _buildRichTextInfo(
              context,
              'Quizalofop-p-ethyl 5% EC:',
              '400–500 ml/ha',
              ' for controlling grassy weeds. Does not harm eggplant.',
            ),
            const SizedBox(height: 16),
            _buildRichTextInfo(
              context,
              'Glyphosate / Glufosinate:',
              'Use only as a directed spray between rows',
              ', shielding crop leaves. This is non-selective and will kill the eggplant if it makes contact.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSafetyPoint(Icons.water_drop, 'Always dilute in 200–250 L water/ha for good coverage.'),
            const Divider(),
            _buildSafetyPoint(Icons.science, 'Stick to the recommended label dose. Eggplant is sensitive to herbicide injury.'),
            const Divider(),
            _buildSafetyPoint(Icons.air, 'Avoid spraying on windy days or when plant leaves are wet.'),
          ],
        ),
      ),
    );
  }


  Widget _buildRichTextInfo(BuildContext context, String title, String value, String description) {
    final textTheme = Theme.of(context).textTheme;
    final boldStyle = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    final valueStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.green.shade700,
    );

    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(height: 1.5),
        children: [
          TextSpan(text: '$title ', style: boldStyle),
          TextSpan(text: value, style: valueStyle),
          TextSpan(text: description),
        ],
      ),
    );
  }

  Widget _buildSafetyPoint(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
    );
  }
}