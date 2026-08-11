import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../providers/auth_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('ASM Production Management',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Risk Summary Cards ──
                    Text('Risk Overview', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${riskSummary['total'] ?? 0} total work orders tracked',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildRiskCard('HIGH', riskSummary['high'] ?? 0, const Color(0xFFEF4444), Icons.error),
                        const SizedBox(width: 12),
                        _buildRiskCard('MEDIUM', riskSummary['medium'] ?? 0, const Color(0xFFF59E0B), Icons.warning_amber),
                        const SizedBox(width: 12),
                        _buildRiskCard('LOW', riskSummary['low'] ?? 0, const Color(0xFF10B981), Icons.check_circle),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Alert Breakdown ──
                    Row(
                      children: [
                        Text('Date Mismatch Alerts', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${riskSummary['totalAlerts'] ?? 0} total',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildAlertChip('Overdue', alertBreakdown['OVERDUE_PROCESS'] ?? 0, const Color(0xFFEF4444)),
                        _buildAlertChip('Seq. Violation', alertBreakdown['SEQUENCE_VIOLATION'] ?? 0, const Color(0xFFF59E0B)),
                        _buildAlertChip('Stale WIP', alertBreakdown['STALE_WIP'] ?? 0, const Color(0xFF8B5CF6)),
                        _buildAlertChip('Missing Date', alertBreakdown['MISSING_DATE'] ?? 0, const Color(0xFF06B6D4)),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Recent Alerts List ──
                    Text('Recent Alerts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (provider.alerts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('No alerts — all processes on track!',
                              style: GoogleFonts.inter(color: const Color(0xFF10B981))),
                        ),
                      )
                    else
                      ...provider.alerts.take(10).map((alert) => _buildAlertCard(alert)),

                    const SizedBox(height: 28),

                    // ── Recent Route Cards ──
                    Row(
                      children: [
                        Text('Route Cards', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/cards'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...provider.routeCards.take(5).map((card) => _buildRouteCardTile(card)),
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
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF082B63), Color(0xFF0B3F8A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.precision_manufacturing, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text('ASM PMS', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Production Management System', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.list_alt_outlined, 'Route Cards', () { Navigator.pop(context); Navigator.pushNamed(context, '/cards'); }),
          _drawerItem(Icons.add_circle_outline, 'Create Route Card', () { Navigator.pop(context); Navigator.pushNamed(context, '/create-card'); }),
          const Divider(color: Color(0xFF334155)),
          _drawerItem(Icons.notifications_outlined, 'Notifications', () { Navigator.pop(context); Navigator.pushNamed(context, '/notifications'); }),
          _drawerItem(Icons.history_outlined, 'Activity Log', () { Navigator.pop(context); Navigator.pushNamed(context, '/activity-log'); }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF94A3B8)),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _buildRiskCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(count.toString(),
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text('$label: $count',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(typeIcons[alert['type']] ?? Icons.warning, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['message'] ?? 'Alert', style: GoogleFonts.inter(fontSize: 13)),
                const SizedBox(height: 2),
                Text('${alert['workOrderNumber'] ?? ''} | ${alert['jobName'] ?? ''}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(severity, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCardTile(Map<String, dynamic> card) {
    final risk = card['riskLevel'] ?? 'LOW';
    final riskColor = risk == 'HIGH' ? const Color(0xFFEF4444)
        : risk == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final progress = card['processProgress'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(risk, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: riskColor)),
              ),
              const SizedBox(width: 8),
              Text(card['cardNumber'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('KO: ${card['koNumber'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 6),
          Text('${card['jobName'] ?? ''} | ${card['partNumber'] ?? ''}',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 10),
          // Mini process timeline
          Row(
            children: progress.map<Widget>((step) {
              final status = step['status'] ?? 'Pending';
              final color = status == 'Completed' ? const Color(0xFF10B981)
                  : status == 'In Progress' ? const Color(0xFF3B82F6)
                  : status == 'Failed' ? const Color(0xFFEF4444)
                  : status == 'N/A' ? Colors.grey.shade600
                  : const Color(0xFF334155);
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
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
