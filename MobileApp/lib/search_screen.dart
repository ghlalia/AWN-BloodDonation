import 'package:flutter/material.dart';
import '../string.dart';
import '../Home/Home_screen.dart';
import '../ui/app_nav.dart' as nav; 
import '../ui/app_ui.dart' as ui; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  List<_SearchResult> _results = const [];

  static const List<_SearchResult> _allCenters = [
    _SearchResult(
      titleEn: 'Central Donation Center – Riyadh · King Fahad Road',
      titleAr: 'مركز التبرع المركزي – الرياض · طريق الملك فهد',
      centerId: 'central',
    ),
    _SearchResult(
      titleEn: 'North Donation Point – Riyadh · An Narjis',
      titleAr: 'نقطة التبرع الشمالية – الرياض · النرجس',
      centerId: 'north',
    ),
    _SearchResult(
      titleEn: 'South Donation Point – Riyadh · Al Aziziyah',
      titleAr: 'نقطة التبرع الجنوبية – الرياض · العزيزية',
      centerId: 'south',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Strings.dir(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: ui.buildAwnAppBar(context),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
             
              TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearch,
                decoration: InputDecoration(
                  hintText: Strings.t(context, 'search'),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

            
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          '${Strings.t(context, "search")}…',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final res = _results[i];
                          final isAr = Localizations.localeOf(context).languageCode == 'ar';
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(isAr ? res.titleAr : res.titleEn),
                              leading: const Icon(Icons.location_on_outlined),
                              onTap: res.centerId == null
                                  ? null
                                  : () => _openOnMap(res.centerId!),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

      
        bottomNavigationBar: nav.buildBottomNav(context, 0),
      ),
    );
  }

  void _onSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _results = const []);
      return;
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final filtered = _allCenters.where((res) {
      final haystack = isAr ? res.titleAr : res.titleEn;
      return haystack.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _results = filtered.isEmpty
          ? [
              _SearchResult(
                titleEn: 'No results for "$query"',
                titleAr: 'لا توجد نتائج لـ "$query"',
                centerId: null,
              ),
            ]
          : filtered;
    });
  }

  void _openOnMap(String centerId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(highlightCenterId: centerId),
      ),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }
}

class _SearchResult {
  final String titleEn;
  final String titleAr;
  final String? centerId;

  const _SearchResult({
    required this.titleEn,
    required this.titleAr,
    required this.centerId,
  });
}
