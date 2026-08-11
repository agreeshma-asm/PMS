import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cards_provider.dart';
import '../config/api_config.dart';

class CardDetailScreen extends StatefulWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  Map<String, dynamic>? _card;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    setState(() => _isLoading = true);
    final result = await Provider.of<CardsProvider>(context, listen: false).fetchCardDetails(widget.cardId);
    setState(() { _card = result; _isLoading = false; });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return const Color(0xFF10B981);
      case 'In Progress': return const Color(0xFF3B82F6);
      case 'Failed': return const Color(0xFFEF4444);
      case 'Deviated': return const Color(0xFFF59E0B);
      case 'N/A': return Colors.grey;
      default: return const Color(0xFF475569);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed': return Icons.check_circle;
      case 'In Progress': return Icons.play_circle_fill;
      case 'Failed': return Icons.cancel;
      case 'Deviated': return Icons.warning;
      case 'N/A': return Icons.remove_circle;
      default: return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Card Details')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (_card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Card Details')),
        body: const Center(child: Text('Card not found')),
      );
    }

    final card = _card!;
    final steps = card['steps'] as List<dynamic>? ?? [];
    final risk = card['riskLevel'] ?? 'LOW';
    final riskColor = risk == 'HIGH' ? const Color(0xFFEF4444)
        : risk == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: Text(card['cardNumber'] ?? 'Route Card',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as Excel',
            onPressed: () {
              launchUrl(Uri.parse('${ApiConfig.baseUrl}/route-cards/${widget.cardId}/export'));
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCard),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Info ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _infoRow('KO Number', card['koNumber'] ?? 'N/A'),
                  _infoRow('Job Name', card['jobName'] ?? ''),
                  _infoRow('Part Number', card['partNumber'] ?? ''),
                  _infoRow('Work Order', card['workOrderNumber'] ?? ''),
                  _infoRow('Batch Qty', '${card['batchQuantity'] ?? 0}'),
                  _infoRow('Status', card['status'] ?? 'Pending'),
                  Row(
                    children: [
                      Text('Risk Level', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(risk, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: riskColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 7-Step Process Pipeline ──
            Text('Process Pipeline', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('7 standard manufacturing steps', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 16),

            // Horizontal progress bar
            Row(
              children: steps.map<Widget>((step) {
                final status = step['status'] ?? 'Pending';
                final color = _getStatusColor(status);
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Individual steps
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final status = step['status'] ?? 'Pending';
              final color = _getStatusColor(status);
              final isIQC = step['processKey'] == 'iqc';
              final iqcResult = step['iqcResult'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getStatusIcon(status), color: color, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Step ${step['stepNumber']}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                              Text(step['operationName'] ?? '',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(step['instructions'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),

                    if (step['signedOffBy'] != null) ...[
                      const SizedBox(height: 6),
                      Text('✓ Signed by: ${step['signedOffBy']} at ${step['signedOffAt'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981))),
                    ],
                    if (step['deviationReason'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('⚠ ${step['deviationReason']}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444))),
                      ),
                    ],

                    // ── IQC Actions ──
                    if (isIQC && status != 'Completed') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (status == 'Pending' || status == 'In Progress') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: Text('Pass', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                onPressed: () async {
                                  await Provider.of<CardsProvider>(context, listen: false)
                                      .signOffStep(card['id'], step['id'], 'QC Inspector', 'Operator', remarks: 'IQC Passed');
                                  _loadCard();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.close, size: 18),
                                label: Text('Fail', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                onPressed: () => _showIQCFailDialog(card['id'], step['id']),
                              ),
                            ),
                          ],
                          if (status == 'Failed') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.replay, size: 18),
                                label: Text('Re-inspect', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                onPressed: () => _showReinspectDialog(card['id'], step['id']),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // ── Regular step actions ──
                    if (!isIQC && (status == 'Pending' || status == 'In Progress')) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (status == 'Pending')
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF3B82F6)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.play_arrow, size: 16, color: Color(0xFF3B82F6)),
                                label: Text('Start', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3B82F6))),
                                onPressed: () async {
                                  await Provider.of<CardsProvider>(context, listen: false)
                                      .progressStep(card['id'], step['id']);
                                  _loadCard();
                                },
                              ),
                            ),
                          if (status == 'In Progress') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: Text('Sign Off', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () async {
                                  await Provider.of<CardsProvider>(context, listen: false)
                                      .signOffStep(card['id'], step['id'], 'Operator', 'Operator');
                                  _loadCard();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.flag, size: 16, color: Color(0xFFEF4444)),
                              label: Text('Flag', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444))),
                              onPressed: () async {
                                await Provider.of<CardsProvider>(context, listen: false)
                                    .flagDeviation(card['id'], step['id'], 'Deviation flagged');
                                _loadCard();
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showIQCFailDialog(String cardId, String stepId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('IQC Fail — Reject / Return to Vendor', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(ctx);
              await Provider.of<CardsProvider>(context, listen: false)
                  .iqcFail(cardId, stepId, reasonController.text, '', 'QC Inspector');
              _loadCard();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showReinspectDialog(String cardId, String stepId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Re-inspect After Vendor Return', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
        content: Text('Initiate re-inspection for this material?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<CardsProvider>(context, listen: false)
                  .iqcReinspect(cardId, stepId, 'Material returned from vendor for re-inspection', 'QC Inspector');
              _loadCard();
            },
            child: const Text('Re-inspect'),
          ),
        ],
      ),
    );
  }
}
