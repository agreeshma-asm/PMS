import re

with open('lib/screens/create_card_screen.dart', 'r') as f:
    content = f.read()

# First, fix the broken bottom part we added
broken_bottom = '''      ),
      // BOM UPLOAD TAB
      _buildBomUploadTab(context, provider),
    ],
  ),
),
      ),
    );
  }'''

content = content.replace(broken_bottom, '''      ),
    );
  }''')

# Now do the top part replacement
top_match = '''  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CardsProvider>(context);
    final wos = provider.workOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Route Card'),
        centerTitle: false,
      ),
      body: SingleChildScrollView('''

replacement_top = '''  @override
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

content = content.replace(top_match, replacement_top)

# Now do the bottom part replacement correctly
bottom_match = '''                ),
              ),
            ],
          ),
        ),
      ),
    );
  }'''

replacement_bottom = '''                ),
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
}'''

content = content.replace(bottom_match, replacement_bottom)

with open('lib/screens/create_card_screen.dart', 'w') as f:
    f.write(content)

print("Done")
