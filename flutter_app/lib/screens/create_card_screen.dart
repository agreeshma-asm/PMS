import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import '../providers/cards_provider.dart';

class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _koController = TextEditingController();
  final _jobNameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _partRevisionController = TextEditingController(text: 'A');
  final _batchQtyController = TextEditingController(text: '1');
  final _workOrderController = TextEditingController();
  final _notesController = TextEditingController();
  String _riskLevel = 'LOW';
  String _complexity = '';
  String? _targetDate;
  bool _isSubmitting = false;

  // Selected WO from PMS dropdown
  Map<String, dynamic>? _selectedWO;

  // BOM Upload
  List<dynamic> _bomItems = [];
  String _bomKoNumber = '';
  final _bomNumberController = TextEditingController();
  bool _isUploadingBom = false;
  bool _isCreatingBulk = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CardsProvider>(context, listen: false).fetchDashboardData();
    });
  }

  void _onWOSelected(Map<String, dynamic> wo) {
    setState(() {
      _selectedWO = wo;
      _workOrderController.text = wo['workOrderNumber'] ?? '';
      _jobNameController.text = wo['jobName'] ?? '';
      _partNumberController.text = wo['partNumber'] ?? '';
      _partRevisionController.text = wo['partRevision'] ?? 'A';
      _batchQtyController.text = (wo['batchQuantity'] ?? 1).toString();
      _riskLevel = wo['riskLevel'] ?? 'LOW';
      _complexity = wo['complexity'] ?? '';
      _targetDate = wo['targetDate'];
      _koController.text = wo['koNumber'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardsProvider>(context);
    final wos = provider.workOrders;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final inputBgColor = Theme.of(context).inputDecorationTheme.fillColor ?? (isDark ? const Color(0xFF0F172A) : Colors.white);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Create Route Card', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            tabs: [
              Tab(icon: Icon(Icons.add_task), text: 'Single Entry'),
              Tab(icon: Icon(Icons.drive_folder_upload), text: 'BOM Upload (Bulk)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PMS Work Order Selection ──
              Row(
                children: [
                  Icon(Icons.work_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Select from PMS Work Orders',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Choose a Work Order...', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    value: _selectedWO != null ? _selectedWO!['workOrderNumber'] : null,
                    dropdownColor: cardColor,
                    items: wos.take(200).map<DropdownMenuItem<String>>((wo) {
                      final risk = wo['riskLevel'] ?? 'LOW';
                      final color = risk == 'HIGH' ? const Color(0xFFEF4444)
                          : risk == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
                      return DropdownMenuItem(
                        value: wo['workOrderNumber'] as String,
                        child: Row(children: [
                          Icon(Icons.circle, size: 10, color: color),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${wo['workOrderNumber']} — ${wo['jobName']}',
                              overflow: TextOverflow.ellipsis)),
                        ]),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final wo = wos.firstWhere((w) => w['workOrderNumber'] == val);
                        _onWOSelected(wo);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 16),

              // ── KO Number (Required) ──
              _buildLabel('KO Number *', isRequired: true),
              TextFormField(
                controller: _koController,
                validator: (v) => (v == null || v.isEmpty) ? 'KO Number is required' : null,
                decoration: _inputDecoration('Enter KO Number'),
              ),

              const SizedBox(height: 16),

              // ── Job Name ──
              _buildLabel('Job Name / Station *'),
              TextFormField(
                controller: _jobNameController,
                validator: (v) => (v == null || v.isEmpty) ? 'Job Name is required' : null,
                decoration: _inputDecoration('Enter Job Name'),
              ),

              const SizedBox(height: 16),

              // ── Part Number & Revision ──
              Row(children: [
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Part Number *'),
                    TextFormField(
                      controller: _partNumberController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      decoration: _inputDecoration('Part Number'),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Revision'),
                    TextFormField(
                      controller: _partRevisionController,
                      decoration: _inputDecoration('Rev'),
                    ),
                  ]),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Work Order & Batch Qty ──
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Work Order *'),
                    TextFormField(
                      controller: _workOrderController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      decoration: _inputDecoration('WO/XXXX'),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel('Batch Quantity'),
                    TextFormField(
                      controller: _batchQtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Qty'),
                    ),
                  ]),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Risk Level (auto-calculated or manual) ──
              _buildLabel('Risk Level'),
              Row(children: [
                for (final r in ['LOW', 'MEDIUM', 'HIGH'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(r),
                      selected: _riskLevel == r,
                      selectedColor: r == 'HIGH' ? const Color(0xFFEF4444)
                          : r == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      onSelected: (selected) { if (selected) setState(() => _riskLevel = r); },
                    ),
                  ),
              ]),

              const SizedBox(height: 16),

              // ── Notes ──
              _buildLabel('Notes'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration('Additional notes...'),
              ),

              const SizedBox(height: 16),

              // ── 7 Standard Processes Preview ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('7-Step Process Pipeline (Auto-Generated)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6))),
                    const SizedBox(height: 12),
                    for (final proc in [
                      {'step': '10', 'name': 'IQC (Incoming Quality Control)'},
                      {'step': '20', 'name': 'RM Cutting'},
                      {'step': '30', 'name': 'Machining'},
                      {'step': '40', 'name': 'Deburring'},
                      {'step': '50', 'name': 'Laser Marking'},
                      {'step': '60', 'name': 'Special Process'},
                      {'step': '70', 'name': 'QC (Final Quality Control)'},
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(child: Text(proc['step']!,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)))),
                          ),
                          const SizedBox(width: 12),
                          Text(proc['name']!, style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Pending', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await Provider.of<CardsProvider>(context, listen: false).createRouteCard({
                        'koNumber': _koController.text,
                        'jobName': _jobNameController.text,
                        'partNumber': _partNumberController.text,
                        'partRevision': _partRevisionController.text,
                        'batchQuantity': int.tryParse(_batchQtyController.text) ?? 1,
                        'workOrderNumber': _workOrderController.text,
                        'riskLevel': _riskLevel,
                        'complexity': _complexity,
                        'targetDate': _targetDate ?? '',
                        'notes': _notesController.text,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Route Card created with 7 standard processes!'), backgroundColor: Color(0xFF10B981)));
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('CREATE ROUTE CARD', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
      _buildBomUploadTab(context, provider),
      ],
    ),
  ),
);
}

  Widget _buildBomUploadTab(BuildContext context, CardsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 48, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                Text('Upload BOM File', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Text('Select an Excel file (.xlsx, .xls) to parse and preview items for bulk Route Card creation.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: subTextColor)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingBom ? null : () async {
                      try {
                        fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
                          type: fp.FileType.custom,
                          allowedExtensions: ['xlsx', 'xls'],
                          withData: kIsWeb,
                        );

                        if (result != null) {
                          setState(() => _isUploadingBom = true);
                          final fileBytes = result.files.first.bytes;
                          final fileName = result.files.first.name;
                          
                          if (fileBytes != null) {
                            final res = await provider.uploadBom(fileBytes, fileName);
                            if (res['success'] == true) {
                              setState(() {
                                _bomKoNumber = res['koNumber'] ?? '';
                                _bomItems = res['items'] ?? [];
                              });
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Upload Error: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                          ));
                        }
                      } finally {
                        setState(() => _isUploadingBom = false);
                      }
                    },
                    icon: _isUploadingBom 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.file_present),
                    label: Text(_isUploadingBom ? 'Parsing...' : 'Browse File', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_bomItems.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Preview: ${_bomItems.length} Items', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text('KO: $_bomKoNumber', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bomItems.length > 5 ? 5 : _bomItems.length,
                separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                itemBuilder: (context, index) {
                  final item = _bomItems[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(item['partNo'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item['description'] ?? '', style: TextStyle(color: subTextColor)),
                    ),
                    trailing: Text('Qty: ${item['qty']}', style: TextStyle(color: subTextColor)),
                  );
                },
              ),
            ),
            if (_bomItems.length > 5)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('+ ${_bomItems.length - 5} more items...', style: const TextStyle(color: Color(0xFF94A3B8)))),
              ),
            const SizedBox(height: 24),
            _buildLabel('BOM Number', isRequired: true),
            TextFormField(
              controller: _bomNumberController,
              decoration: _inputDecoration('Enter BOM Number (e.g. BOM-001)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isCreatingBulk ? null : () async {
                  setState(() => _isCreatingBulk = true);
                  try {
                    if (_bomNumberController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a BOM Number')));
                      setState(() => _isCreatingBulk = false);
                      return;
                    }
                    final createdCount = await provider.bulkCreateRouteCards(_bomKoNumber, _bomNumberController.text.trim(), _bomItems);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully created $createdCount route cards!'), backgroundColor: const Color(0xFF10B981)));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
                    }
                  } finally {
                    if (mounted) setState(() => _isCreatingBulk = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCreatingBulk
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('CONFIRM & GENERATE ROUTE CARDS', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
    );
  }
}


