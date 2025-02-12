import 'package:flutter/material.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.security, 'label': 'Security sensors'},
      {'icon': Icons.ac_unit, 'label': 'Air Conditioner'},
      {'icon': Icons.fireplace, 'label': 'Fire detection'},
      {'icon': Icons.lightbulb, 'label': 'Lights'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature['icon'] as IconData, size: 40),
              const SizedBox(height: 8),
              Text(feature['label'] as String),
            ],
          ),
        );
      },
    );
  }
}