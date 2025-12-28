
enum AccountRole { individual, site }

class UserProfile {
  final String name;
  final int age;
  final String bloodType; 
  final String? phone;
  final String? location;

  const UserProfile({
    required this.name,
    required this.age,
    required this.bloodType,
    this.phone,
    this.location,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? bloodType,
    String? phone,
    String? location,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        bloodType: bloodType ?? this.bloodType,
        phone: phone ?? this.phone,
        location: location ?? this.location,
      );
}

class Vitals {
  final int systolic;   // الضغط الأعلى
  final int diastolic;  // الضغط الأدنى
  final int pulse;          
  final int? oxygenLevel; 
  final int? heartRate;   
  const Vitals({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    this.oxygenLevel,
    this.heartRate,
  });
}

class Appointment {
  final String id;
  final String centerId;     
  final String centerName;  
  final DateTime dateTime;   // وقت الموعد
  final String? donorName;   // يظهر لموقع التبرع
  final String? donorBloodType;
  Appointment({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.dateTime,
    this.donorName,
    this.donorBloodType,
  });

  Appointment copyWith({
    String? centerId,
    String? centerName,
    DateTime? dateTime,
    String? donorName,
    String? donorBloodType,
  }) =>
      Appointment(
        id: id,
        centerId: centerId ?? this.centerId,
        centerName: centerName ?? this.centerName,
        dateTime: dateTime ?? this.dateTime,
        donorName: donorName ?? this.donorName,
        donorBloodType: donorBloodType ?? this.donorBloodType,
      );
}

class InventoryItem {
  final String bloodType;
  int units;                 // عدد الأكياس
  int minRequired;           // الحد الأدنى
  InventoryItem({required this.bloodType, required this.units, required this.minRequired});
}

/// نتيجة فحص الأهلية
class EligibilityResult {
  final bool ok;
  final String? reasonKey; 
  const EligibilityResult.ok() : ok = true, reasonKey = null;
  const EligibilityResult.fail(this.reasonKey) : ok = false;
}
