import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class BlocAppMark extends StatelessWidget {
  const BlocAppMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.crop_square_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
