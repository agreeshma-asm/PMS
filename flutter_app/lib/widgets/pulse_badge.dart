import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PulseBadge extends StatefulWidget {
  final String text;
  final Color color;

  const PulseBadge({super.key, required this.text, required this.color});

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.15, end: 0.4).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text != 'HIGH') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: widget.color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(widget.text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: widget.color)),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: widget.color.withOpacity(_animation.value), borderRadius: BorderRadius.circular(4)),
          child: Text(widget.text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: widget.color)),
        );
      },
    );
  }
}
