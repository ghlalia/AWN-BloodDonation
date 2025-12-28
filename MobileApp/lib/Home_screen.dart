import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../string.dart';
import '../core/session.dart';
import '../core/auth_guard.dart';
import '../core/models.dart';
import '../core/data_store.dart';

import '../booking/booking_screen.dart'; 
import '../ui/app_nav.dart' as nav;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.highlightCenterId});

  final String? highlightCenterId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ألوان المشروع
  static const Color awnRed = Color(0xFFC62828);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color bgLight = Color(0xFFF7F7F7);
  static const Color pinGrey = Color(0xFF7A7A7A);

  GoogleMapController? _mapController;
  static const LatLng _riyadhCenter = LatLng(24.7136, 46.6753);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _riyadhCenter,
    zoom: 12,
  );
  static final LatLngBounds _riyadhBounds = LatLngBounds(
    southwest: const LatLng(24.3, 46.2),
    northeast: const LatLng(25.1, 47.2),
  );

  final List<_CenterInfo> _centers = const [
    _CenterInfo(
      titleEn: 'Central Donation Center',
      titleAr: 'مركز التبرع المركزي',
      areaEn: 'Riyadh · King fahad Road',
      areaAr: 'الرياض · طريق الملك فهد',
      location: LatLng(24.713704, 46.675297),
    ),
    _CenterInfo(
      titleEn: 'North Donation Point',
      titleAr: 'نقطة التبرع الشمالية',
      areaEn: 'Riyadh · Al Narjis',
      areaAr: 'الرياض · النرجس',
      location: LatLng(24.885262, 46.653393),
    ),
    _CenterInfo(
      titleEn: 'South Donation Point',
      titleAr: 'نقطة التبرع الجنوبية',
      areaEn: 'Riyadh · Al Aziziyah',
      areaAr: 'الرياض · العزيزية',
      location: LatLng(24.605226, 46.707912),
    ),
  ];

  int? _selected; 
  int? _pendingSelect;
  final Map<String, String> _siteIdByName = {}; // map site name -> Firestore doc id

  @override
  void initState() {
    super.initState();
    _selected = _indexForCenterId(widget.highlightCenterId);
    _pendingSelect = _selected;
    _loadSiteIds();
  }

  String t(BuildContext context, String key) => Strings.t(context, key);
  TextDirection dir(BuildContext context) => Strings.dir(context);

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToPendingCenter();
  }

  void _onCenterSelected(int index) {
    setState(() => _selected = index);
    _animateToCenter(index);
  }

  void _animateToCenter(int index) {
    final target = _centers[index].location;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 13));
  }

  void _animateToPendingCenter() {
    final idx = _pendingSelect;
    if (idx == null) return;
    _pendingSelect = null;
    _animateToCenter(idx);
  }

  Future<void> _loadSiteIds() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('donationsites').get();
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['SiteName'] as String?)?.toLowerCase();
        final altName = (data['name'] as String?)?.toLowerCase();
        final siteIdField = (data['siteID'] as String?)?.toLowerCase() ?? (data['siteId'] as String?)?.toLowerCase();
        final docId = doc.id;
        for (final key in [name, altName, siteIdField]) {
          if (key != null && key.isNotEmpty) {
            map[key] = docId;
          }
        }
      }
      if (mounted) {
        setState(() {
          _siteIdByName
            ..clear()
            ..addAll(map);
        });
      }
    } catch (_) {
      
    }
  }

  String _siteIdFor(_CenterInfo c) {
    final en = c.titleEn.toLowerCase();
    final ar = c.titleAr.toLowerCase();
    return _siteIdByName[en] ??
        _siteIdByName[ar] ??
        _centerIdFor(c); 
  }

  Set<Marker> _buildMarkers(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return _centers.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      final selected = _selected == i;
      return Marker(
        markerId: MarkerId('center_$i'),
        position: c.location,
        infoWindow: InfoWindow(
          title: isAr ? c.titleAr : c.titleEn,
          snippet: isAr ? c.areaAr : c.areaEn,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        onTap: () => _onCenterSelected(i),
      );
    }).toSet();
  }

  void _recenterMap() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_riyadhCenter, 12),
    );
  }

  Future<void> _handleBook() async {
    if (_selected == null) return;
    if (!Session.isLoggedIn) {
      await AuthGuard.requireLogin(context);
      return;
    }

    if (Session.accountRole == AccountRole.site) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.t(context, 'siteCannotBook'))),
      );
      return;
    }

    final c = _centers[_selected!];
    final siteId = _siteIdFor(c);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          centerId: siteId, 
          centerName: _centerNameFor(context, c),
        ),
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.t(context, 'bookedSuccessfully'))),
      );
    }
  }

  
  String _centerIdFor(_CenterInfo c) {
    if (c.titleEn.contains('Central')) return 'central';
    if (c.titleEn.contains('North')) return 'north';
    return 'south';
  }

  String _centerNameFor(BuildContext ctx, _CenterInfo c) {
    final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
    return isAr ? c.titleAr : c.titleEn;
  }

  int? _indexForCenterId(String? centerId) {
    if (centerId == null) return null;
    for (var i = 0; i < _centers.length; i++) {
      if (_centerIdFor(_centers[i]) == centerId) return i;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: dir(context),
      child: Scaffold(
        backgroundColor: bgLight,

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          titleSpacing: 0,
          leadingWidth: 120, // مساحة للوقو
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 50, // logo size
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'en') {
                  await LocaleScope.of(context).setLocale(const Locale('en'));
                } else if (value == 'ar') {
                  await LocaleScope.of(context).setLocale(const Locale('ar'));
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'en', child: Text('English')),
                PopupMenuItem(value: 'ar', child: Text('العربية')),
              ],
            ),
          ],
        ),

        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _initialCameraPosition,
                markers: _buildMarkers(context),
                cameraTargetBounds: CameraTargetBounds(_riyadhBounds),
                zoomControlsEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                onTap: (_) => setState(() => _selected = null),
              ),
            ),

            if (_selected != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 90, 
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  offset: const Offset(0, 0), 
                  child: _BottomBookingBar(
                    title: isAr
                        ? _centers[_selected!].titleAr
                        : _centers[_selected!].titleEn,
                    area: isAr
                        ? _centers[_selected!].areaAr
                        : _centers[_selected!].areaEn,
                    siteId: _siteIdFor(_centers[_selected!]),
                    onClose: () => setState(() => _selected = null),
                    onBook: _handleBook, 
                  ),
                ),
              ),
          ],
        ),

        floatingActionButton: _SmallSquareFAB(
          onPressed: _recenterMap,
          icon: Icons.location_searching,
          color: awnRed,
        ),

        bottomNavigationBar: nav.buildBottomNav(context, 1),
      ),
    );
  }
}


class _SmallSquareFAB extends StatelessWidget {
  const _SmallSquareFAB({
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  const _BottomBookingBar({
    required this.title,
    required this.area,
    required this.siteId,
    required this.onClose,
    required this.onBook,
  });

  final String title;
  final String area;
  final String siteId;
  final VoidCallback onClose;
  final Future<void> Function() onBook;

  static const Color awnRed = Color(0xFFC62828);
  static const Color textDark = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
 
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(area, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StreamBuilder<List<String>>(
                    stream: DataStore.instance.watchNeededBloodTypes(siteId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('${Strings.t(context, 'shortages')}: ...');
                      }
                      final needed = snapshot.data ?? const [];
                      final text = needed.isEmpty ? '—' : needed.join(', ');
                      return Text(
                        '${Strings.t(context, 'shortages')}: $text',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => onBook(),
              style: ElevatedButton.styleFrom(
                backgroundColor: awnRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(Strings.t(context, 'book')),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              splashRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterInfo {
  final String titleEn, titleAr;
  final String areaEn, areaAr;
  final LatLng location;
  const _CenterInfo({
    required this.titleEn,
    required this.titleAr,
    required this.areaEn,
    required this.areaAr,
    required this.location,
  });
}
