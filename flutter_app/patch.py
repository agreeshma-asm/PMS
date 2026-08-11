import re

with open('lib/screens/create_card_screen.dart', 'r') as f:
    content = f.read()

# State variables
state_vars = '''  bool _isSubmitting = false;

  // Selected WO from PMS dropdown
  Map<String, dynamic>? _selectedWO;

  // BOM Upload
  List<dynamic> _bomItems = [];
  String _bomKoNumber = '';
  bool _isUploadingBom = false;
  bool _isCreatingBulk = false;'''

content = re.sub(r'  bool _isSubmitting = false;\n\n  // Selected WO from PMS dropdown\n  Map<String, dynamic>\? _selectedWO;', state_vars, content)

# TabController
build_start = '''
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardsProvider>(context);
    final wos = provider.workOrders;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text('Create Route Card', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            tabs: [
              Tab(text: 'Single Entry'),
              Tab(text: 'BOM Upload (Bulk)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView('''

content = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{\n    final provider = Provider\.of<CardsProvider>\(context\);\n    final wos = provider\.workOrders;\n\n    return Scaffold\(\n      backgroundColor: const Color\(0xFF0F172A\),\n      appBar: AppBar\(\n        title: Text\(\'Create Route Card\', style: GoogleFonts\.inter\(fontWeight: FontWeight\.w600\)\),\n        backgroundColor: const Color\(0xFF1E293B\),\n        elevation: 0,\n      \),\n      body: SingleChildScrollView\(', build_start, content)

# End of Single Entry tab and start of BOM tab
end_scaffold = '''              ),
            ],
          ),
        ),
      ),
    );
  }'''

bom_tab = '''              ),
            ],
          ),
        ),
            // BOM UPLOAD TAB
            _buildBomUploadTab(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBomUploadTab(BuildContext context, CardsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 48, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                Text('Upload BOM File', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Select an Excel file (.xlsx, .xls) to parse and preview items for bulk Route Card creation.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingBom ? null : () async {
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ')));
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
                Text('Preview:  Items', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text('KO: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bomItems.length > 5 ? 5 : _bomItems.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                itemBuilder: (context, index) {
                  final item = _bomItems[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(item['partNo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item['description'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    trailing: Text('Qty: ', style: const TextStyle(color: Color(0xFF94A3B8))),
                  );
                },
              ),
            ),
            if (_bomItems.length > 5)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('+  more items...', style: const TextStyle(color: Color(0xFF94A3B8)))),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isCreatingBulk ? null : () async {
                  setState(() => _isCreatingBulk = true);
                  try {
                    final createdCount = await provider.bulkCreateRouteCards(_bomKoNumber, _bomItems);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully created  route cards!'), backgroundColor: const Color(0xFF10B981)));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: '), backgroundColor: const Color(0xFFEF4444)));
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
  }'''

content = content.replace(end_scaffold, bom_tab)

with open('lib/screens/create_card_screen.dart', 'w') as f:
    f.write(content)

print("Done")
