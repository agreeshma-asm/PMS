import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pulse_badge.dart';

import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CardsProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardsProvider>(context);
    final riskSummary = provider.riskSummary;
    final alertBreakdown = riskSummary['alertBreakdown'] as Map<String, dynamic>? ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white : Colors.black);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: Text('ASM Production Management',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.fetchDashboardData()),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: provider.fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Risk Summary Cards ──
                    Row(
                      children: [
                        const Icon(Icons.analytics, size: 20, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text('Risk Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                        const Spacer(),
                        Text('${riskSummary['total'] ?? 0} active WOs', style: GoogleFonts.inter(fontSize: 12, color: subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRiskCard('HIGH', riskSummary['high'] ?? 0, const Color(0xFFEF4444), Icons.error, cardColor),
                        const SizedBox(width: 8),
                        _buildRiskCard('MEDIUM', riskSummary['medium'] ?? 0, const Color(0xFFF59E0B), Icons.warning_amber, cardColor),
                        const SizedBox(width: 8),
                        _buildRiskCard('LOW', riskSummary['low'] ?? 0, const Color(0xFF10B981), Icons.check_circle, cardColor),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Alert Breakdown ──
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Text('Date Mismatch Alerts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${riskSummary['totalAlerts'] ?? 0} total',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAlertChip('Overdue', alertBreakdown['OVERDUE_PROCESS'] ?? 0, const Color(0xFFEF4444), cardColor),
                        _buildAlertChip('Seq. Violation', alertBreakdown['SEQUENCE_VIOLATION'] ?? 0, const Color(0xFFF59E0B), cardColor),
                        _buildAlertChip('Stale WIP', alertBreakdown['STALE_WIP'] ?? 0, const Color(0xFF8B5CF6), cardColor),
                        _buildAlertChip('Missing Date', alertBreakdown['MISSING_DATE'] ?? 0, const Color(0xFF06B6D4), cardColor),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Recent Alerts List ──
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 20, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Text('Recent Alerts', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (provider.alerts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No alerts — all processes on track!',
                              style: GoogleFonts.inter(color: const Color(0xFF10B981))),
                        ),
                      )
                    else
                      ...provider.alerts.take(10).map((alert) => _buildAlertCard(alert, cardColor, textColor, subTextColor)),

                    const SizedBox(height: 16),

                    // ── Recent Route Cards ──
                    Row(
                      children: [
                        const Icon(Icons.view_list, size: 20, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text('Route Cards', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/cards'),
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...provider.routeCards.take(5).map((card) => _buildRouteCardTile(card, cardColor, textColor, subTextColor)),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-card'),
        icon: const Icon(Icons.add),
        label: const Text('New Card'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [const Color(0xFF082B63), const Color(0xFF0B3F8A)] : [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.precision_manufacturing, size: 32, color: Colors.white),
                const SizedBox(height: 4),
                Text('ASM PMS', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Production Management System', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          _drawerItem(context, Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(context, Icons.list_alt_outlined, 'Route Cards', () { Navigator.pop(context); Navigator.pushNamed(context, '/cards'); }),
          _drawerItem(context, Icons.add_circle_outline, 'Create Route Card', () { Navigator.pop(context); Navigator.pushNamed(context, '/create-card'); }),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          _drawerItem(context, Icons.notifications_outlined, 'Notifications', () { Navigator.pop(context); Navigator.pushNamed(context, '/notifications'); }),
          _drawerItem(context, Icons.history_outlined, 'Activity Log', () { Navigator.pop(context); Navigator.pushNamed(context, '/activity-log'); }),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
      onTap: onTap,
    );
  }

  Widget _buildRiskCard(String label, int count, Color color, IconData icon, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(count.toString(),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChip(String label, int count, Color color, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text('$label: $count',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, Color cardColor, Color? textColor, Color subTextColor) {
    final severity = alert['severity'] ?? 'LOW';
    final color = severity == 'HIGH' ? const Color(0xFFEF4444)
        : severity == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);
    final typeIcons = {
      'OVERDUE_PROCESS': Icons.timer_off,
      'SEQUENCE_VIOLATION': Icons.swap_vert,
      'STALE_WIP': Icons.hourglass_bottom,
      'MISSING_DATE': Icons.event_busy,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(typeIcons[alert['type']] ?? Icons.warning, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['message'] ?? 'Alert', style: GoogleFonts.inter(fontSize: 12, color: textColor)),
                Text('${alert['workOrderNumber'] ?? ''} | ${alert['jobName'] ?? ''}',
                    style: GoogleFonts.inter(fontSize: 10, color: subTextColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(severity, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCardTile(Map<String, dynamic> card, Color cardColor, Color? textColor, Color subTextColor) {
    final risk = card['riskLevel'] ?? 'LOW';
    final riskColor = risk == 'HIGH' ? const Color(0xFFEF4444)
        : risk == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final progress = card['processProgress'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulseBadge(text: risk, color: riskColor),
              const SizedBox(width: 8),
              Text(card['cardNumber'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Text('KO: ${card['koNumber'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 11, color: subTextColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${card['jobName'] ?? ''} | ${card['partNumber'] ?? ''}',
              style: GoogleFonts.inter(fontSize: 11, color: subTextColor)),
          const SizedBox(height: 8),
          // Mini process timeline
          Row(
            children: progress.map<Widget>((step) {
              final status = step['status'] ?? 'Pending';
              final color = status == 'Completed' ? const Color(0xFF10B981)
                  : status == 'In Progress' ? const Color(0xFF3B82F6)
                  : status == 'Failed' ? const Color(0xFFEF4444)
                  : status == 'N/A' ? Colors.grey.shade400
                  : const Color(0xFFCBD5E1); // Neutral for both themes
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text('${card['completedSteps'] ?? 0}/${card['stepCount'] ?? 7} steps completed',
              style: GoogleFonts.inter(fontSize: 10, color: subTextColor)),
        ],
      ),
    );
  }
}
