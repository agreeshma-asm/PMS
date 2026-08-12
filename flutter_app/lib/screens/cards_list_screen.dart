import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../providers/auth_provider.dart';
import 'card_detail_screen.dart';
import '../widgets/pulse_badge.dart';

class CardsListScreen extends StatefulWidget {
  const CardsListScreen({super.key});

  @override
  State<CardsListScreen> createState() => _CardsListScreenState();
}

class _CardsListScreenState extends State<CardsListScreen> {
  String _riskFilter = 'ALL';
  String _koFilter = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardsProvider>(context);
    List<dynamic> cards = provider.routeCards;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    // Apply filters
    if (_riskFilter != 'ALL') {
      cards = cards.where((c) => c['riskLevel'] == _riskFilter).toList();
    }
    if (_koFilter.isNotEmpty) {
      cards = cards.where((c) => (c['koNumber'] ?? '').toString().contains(_koFilter)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Route Cards', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.fetchDashboardData()),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cardColor,
            child: Row(
              children: [
                // Risk filter chips
                for (final r in ['ALL', 'HIGH', 'MEDIUM', 'LOW'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(r, style: GoogleFonts.inter(fontSize: 11)),
                      selected: _riskFilter == r,
                      selectedColor: r == 'HIGH' ? const Color(0xFFEF4444)
                          : r == 'MEDIUM' ? const Color(0xFFF59E0B)
                          : r == 'LOW' ? const Color(0xFF10B981)
                          : const Color(0xFF3B82F6),
                      onSelected: (s) { if (s) setState(() => _riskFilter = r); },
                    ),
                  ),
                const SizedBox(width: 8),
                // KO number search
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      onChanged: (v) => setState(() => _koFilter = v),
                      decoration: InputDecoration(
                        hintText: 'Search KO...',
                        hintStyle: GoogleFonts.inter(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Cards List ──
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : cards.isEmpty
                    ? Center(child: Text('No cards found', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _buildCardTile(context, card);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Provider.of<AuthProvider>(context, listen: false).userRole != 'Operator' 
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/create-card'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCardTile(BuildContext context, Map<String, dynamic> card) {
    final risk = card['riskLevel'] ?? 'LOW';
    final riskColor = risk == 'HIGH' ? const Color(0xFFEF4444)
        : risk == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final progress = card['processProgress'] as List<dynamic>? ?? [];
    final completed = card['completedSteps'] ?? 0;
    final total = card['stepCount'] ?? 7;
    final failed = card['failedSteps'] ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: card['id'])),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                PulseBadge(text: risk, color: riskColor),
                const SizedBox(width: 8),
                Text(card['cardNumber'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const Spacer(),
                if (failed > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 3),
                        Text('$failed Failed', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFEF4444))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${card['jobName'] ?? ''} — ${card['partNumber'] ?? ''}',
                style: GoogleFonts.inter(fontSize: 13, color: subTextColor)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('KO: ${card['koNumber'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 12, color: subTextColor)),
                const SizedBox(width: 12),
                Text('WO: ${card['workOrderNumber'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: subTextColor)),
                const Spacer(),
                Text('$completed/$total steps', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: subTextColor)),
              ],
            ),

            const SizedBox(height: 10),
            // Mini process timeline
            Row(
              children: progress.map<Widget>((step) {
                final status = step['status'] ?? 'Pending';
                final color = status == 'Completed' ? const Color(0xFF10B981)
                    : status == 'In Progress' ? const Color(0xFF3B82F6)
                    : status == 'Failed' ? const Color(0xFFEF4444)
                    : status == 'N/A' ? Colors.grey.shade400
                    : const Color(0xFFCBD5E1);
                return Expanded(
                  child: Tooltip(
                    message: '${step['operationName']}: $status',
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
