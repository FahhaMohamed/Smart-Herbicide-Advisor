import 'package:flutter/material.dart';

// A data class to hold the generated recommendation.
class Recommendation {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  Recommendation({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}

// A service class containing the logic to generate recommendations.
class RecommendationService {

  Recommendation getRecommendation(List<String> detectedLabels) {
    // Convert the list of labels into a Set for efficient lookup.
    final Set<String> uniqueLabels = Set<String>.from(detectedLabels);

    // Check for the presence of weeds.
    bool hasWeeds = uniqueLabels.any((label) => 
      label.toLowerCase().contains('purslane') || 
      label.toLowerCase().contains('grass'));

    // If no weeds are detected, return a positive message.
    if (!hasWeeds) {
      return Recommendation(
        title: "No Weeds Detected!",
        content: "The area around your crop appears clear. Continue to monitor for new weed growth.",
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }

    // --- LOGIC FOR RECOMMENDATIONS WHEN WEEDS ARE PRESENT ---

    bool isEarlyStage = uniqueLabels.any((label) => label.toLowerCase().contains('early-eggplant'));
    bool isMatureStage = uniqueLabels.any((label) => label.toLowerCase().contains('mature-eggplant'));

    // Scenario 1: Weeds detected with Early Stage Eggplant
    if (isEarlyStage) {
      return Recommendation(
        title: "Action Required: Early Stage Weed Control",
        content: "Your eggplant is young and vulnerable. Use a PRE-EMERGENCE herbicide.\n\n"
                 "• Recommendation: Pendimethalin 30% EC.\n"
                 "• Ratio: 1.0 - 1.5 L/acre mixed in 200 L of water.\n\n"
                 "Apply carefully to the soil without touching the young plant leaves.",
        icon: Icons.energy_savings_leaf,
        color: Colors.orange,
      );
    }

    // Scenario 2: Weeds detected with Mature Stage Eggplant
    if (isMatureStage) {
      return Recommendation(
        title: "Action Required: Mature Stage Weed Control",
        content: "Your eggplant is established. Use a POST-EMERGENCE selective herbicide for grassy weeds or a directed spray for others.\n\n"
                 "• For Grass: Quizalofop-p-ethyl 5% EC at 400 ml/ha.\n"
                 "• For Other Weeds: Use Glyphosate as a DIRECTED spray BETWEEN rows, shielding the crop completely.",
        icon: Icons.eco,
        color: Colors.blue,
      );
    }

    // Fallback Scenario: Weeds detected, but no eggplant stage identified.
    // This is a general recommendation.
    return Recommendation(
      title: "Weeds Detected",
      content: "Weeds are present. The ideal herbicide depends on your crop's growth stage. Please refer to the full Weed Control Guide for detailed instructions.",
      icon: Icons.grass,
      color: Colors.brown,
    );
  }
}