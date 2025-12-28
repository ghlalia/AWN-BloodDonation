import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../string.dart';
import '../core/models.dart';
import '../core/data_store.dart';
import '../core/session.dart';

class SiteAccountScreen extends StatefulWidget {
  const SiteAccountScreen({super.key});

  @override
  State<SiteAccountScreen> createState() => _SiteAccountScreenState();
}

class _SiteAccountScreenState extends State<SiteAccountScreen> {
  String t(String k) => Strings.t(context, k);
  static const List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<InventoryItem> _inventory = [];
  Future<DonationSite?>? _siteFuture;
  String? _siteDocId;
  String? _siteAppointmentsId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _siteAppointmentsStream;

  @override
  void initState() {
    super.initState();
    
    _siteFuture = DataStore.instance.getCurrentDonationSite();
    _siteFuture?.then((site) {
      if (!mounted || site == null) return;
      final effectiveSiteDocId = site.docId;
      final effectiveAppointmentsId = site.siteId.isNotEmpty ? site.siteId : site.docId;
      debugPrint('Subscribing to site appointments for $effectiveSiteDocId');
      setState(() {
        _siteDocId = effectiveSiteDocId;
        _siteAppointmentsId = effectiveAppointmentsId;
        _siteAppointmentsStream = FirebaseFirestore.instance
            .collection('donationsites')
            .doc(effectiveAppointmentsId)
            .collection('siteappointments')
            .orderBy('date', descending: false)
            .snapshots();
      });
      _loadData(siteDocId: effectiveSiteDocId);
    });
  }

  Future<void> _loadData({String? siteDocId}) async {
    final effectiveSiteId = siteDocId ?? _siteDocId;
    if (effectiveSiteId == null) return;

    try {
      final siteRef = FirebaseFirestore.instance.collection('donationsites').doc(effectiveSiteId);
      final futures = _bloodTypes.map(
        (blood) => siteRef.collection('inventory').doc(blood).get(),
      );
      final docs = await Future.wait(futures);
      final inventory = <InventoryItem>[];
      for (final doc in docs) {
        final data = doc.data();
        final blood = data?['bloodType'] as String? ?? doc.id;
        final units = (data?['units'] as num?)?.toInt() ?? 0;
        inventory.add(InventoryItem(bloodType: blood, units: units, minRequired: 5));
      }
      setState(() {
        _inventory = inventory;
      });
    } catch (_) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DonationSite?>(
      future: _siteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text(t('accountNotFound')));
        }

        final site = snapshot.data!;
        final shortages =
            _inventory.where((e) => e.units < e.minRequired).map((e) => e.bloodType).toList();
        final inv = _inventory;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _summaryCard(site, shortages),
            const SizedBox(height: 16),
            _inventoryCard(site, inv),
            const SizedBox(height: 16),
            _bookingsCard(_siteAppointmentsId ?? site.docId),
          ],
        );
      },
    );
  }

  Widget _summaryCard(DonationSite site, List<String> shortages) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE3F2FD),
                  child: Icon(Icons.local_hospital, color: const Color(0xFF1565C0)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // show site name instead of uid
                      Text(
                        site.siteName.isNotEmpty ? site.siteName : 'Donation site',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Donation site ID: ${site.siteId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<String>>(
              stream: DataStore.instance.watchNeededBloodTypes(site.docId),
              builder: (context, snapshot) {
                final needed = (snapshot.data != null && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : shortages;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: needed.isEmpty ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    needed.isEmpty
                        ? t('noShortages')
                        : '${t('shortages')}: ${needed.join(', ')}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryCard(DonationSite site, List<InventoryItem> inv) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('inventoryPanel'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ...inv.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.bloodType, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => _adjustUnits(e, -1),
                      ),
                      Text('${e.units}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => _adjustUnits(e, 1),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _loadData(siteDocId: site.docId),
              icon: const Icon(Icons.refresh),
              label: Text(t('refresh')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingsCard(String siteId) {
    if (_siteAppointmentsStream == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(t('loginDonor')),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('upcomingAppointments'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _siteAppointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Site appt error: ${snapshot.error}');
                  return Text(t('errorOccurred'));
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                unawaited(_cleanupOrphanSiteAppointments(allDocs));
                // auto-complete past appointments
                unawaited(_maybeCompleteSiteAppointments(allDocs, siteId));
               
                final docs = allDocs.where((d) {
                  final data = d.data();
                  final status = (data['status'] as String?) ?? 'upcoming';
                  return status == 'upcoming';
                }).toList();

                debugPrint('Loaded ${docs.length} site appointments for $siteId');

                if (docs.isEmpty) {
                  return Text(t('noAppointments'));
                }

                return Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final dt = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final donorName = data['donorname'] as String?;
                    final donorBloodType = data['donorBloodType'] as String?;
                    final status = data['status'] as String? ?? 'upcoming';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('upcomingAppointments'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatDateTime(dt)),
                          const SizedBox(height: 6),
                          Text('${t('donorRole')}: ${donorName ?? t('unknownDonor')}'),
                          Text('${t('bloodType')}: ${donorBloodType ?? '-'}'),
                          Text('${t('status')}: $status'),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustUnits(InventoryItem item, int delta) async {
    final siteId = _siteDocId;
    if (siteId == null) return;
    final newUnits = (item.units + delta).clamp(0, 1000000).toInt();
    await DataStore.instance.updateInventory(
      siteId: siteId,
      bloodType: item.bloodType,
      units: newUnits,
    );
    setState(() => item.units = newUnits);
  }

  // remove site appointments whose donor record was deleted/cancelled
  Future<void> _cleanupOrphanSiteAppointments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    for (final d in docs) {
      final data = d.data();
      final status = (data['status'] as String?) ?? 'upcoming';
      if (status != 'upcoming') continue;
      final donorId = data['donorid'] as String?;
      final appointmentId = (data['appointmentID'] as String?) ?? d.id;
      if (donorId == null) continue;

      final donorCol = FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .collection('donorappointments');

      DocumentSnapshot<Map<String, dynamic>>? donorDoc;
      try {
        donorDoc = await donorCol.doc(appointmentId).get();
      } catch (_) {}

      if (donorDoc == null || !donorDoc.exists) {
        try {
          final q = await donorCol.where('appointmentID', isEqualTo: appointmentId).limit(1).get();
          if (q.docs.isNotEmpty) donorDoc = q.docs.first;
        } catch (_) {}
      }

      final donorStatus = donorDoc?.data()?['status'] as String?;
      final donorMissingOrCancelled = donorDoc == null || !donorDoc.exists || donorStatus == 'cancelled';
      if (donorMissingOrCancelled) {
        try {
          await d.reference.delete();
        } catch (_) {}
      }
    }
  }

  // mark past dated appointments as completed on site + donor records
  Future<void> _maybeCompleteSiteAppointments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String siteId,
  ) async {
    final now = DateTime.now();
    for (final d in docs) {
      final data = d.data();
      final status = (data['status'] as String?) ?? 'upcoming';
      if (status != 'upcoming') continue;
      final dt = (data['date'] as Timestamp?)?.toDate();
      if (dt == null || dt.isAfter(now)) continue;
      final appointmentId = (data['appointmentID'] as String?) ?? d.id;
      final donorId = data['donorid'] as String?;
      await _setSiteAppointmentStatus(
        siteId: siteId,
        siteAppointmentId: appointmentId,
        donorId: donorId,
        status: 'completed',
      );
    }
  }

  Future<void> _setSiteAppointmentStatus({
    required String siteId,
    required String siteAppointmentId,
    required String? donorId,
    required String status,
  }) async {
    final siteRef = FirebaseFirestore.instance
        .collection('donationsites')
        .doc(siteId)
        .collection('siteappointments')
        .doc(siteAppointmentId);
    try {
      await siteRef.set({'status': status}, SetOptions(merge: true));
    } catch (_) {}

    if (donorId != null) {
      final donorCollection = FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .collection('donorappointments');
      try {
        await donorCollection.doc(siteAppointmentId).set({'status': status}, SetOptions(merge: true));
      } catch (_) {
        try {
          final q = await donorCollection.where('appointmentID', isEqualTo: siteAppointmentId).limit(1).get();
          if (q.docs.isNotEmpty) {
            await q.docs.first.reference.set({'status': status}, SetOptions(merge: true));
          }
        } catch (_) {}
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
