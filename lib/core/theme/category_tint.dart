import 'package:flutter/material.dart';

LinearGradient categoryTint(String category) {
  const begin = Alignment.topLeft;
  const end = Alignment.bottomRight;
  return switch (category) {
    'Cakes & Pastries' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFDE8F4), Color(0xFFF58CCB)],
    ),
    'Kulfi' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
    ),
    'Candies, Dollies & Bars' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFF4FCE3), Color(0xFFD9F99D)],
    ),
    'Cones' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
    ),
    'Cups' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
    ),
    'Gully Gola' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
    ),
    'Take Home' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
    ),
    'Sugar Free' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
    ),
    'Novelties' => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFFFBEB), Color(0xFFFED7AA)],
    ),
    _ => const LinearGradient(
      begin: begin,
      end: end,
      colors: [Color(0xFFFFF0F8), Color(0xFFFDE8F4)],
    ),
  };
}
