# AWN-BloodDonation

Awn is an end-to-end blood donation system that integrates a Flutter mobile application with a wearable IoT device to support donor eligibility checks, appointment scheduling, and blood inventory management.
The system is designed to improve coordination between donors and donation sites through real-time data and cloud synchronization.

-----------------------------------------
INSTALLATION


Prerequisites

-Flutter SDK

-Android Studio or Android SDK

-VS Code (recommended)

Steps

1-Clone the repository.

2-Open the project in VS Code.

3-Install dependencies:

flutter pub get

4-Connect a physical Android device or launch an Android emulator.

5-Run the application:

flutter run


-----------------------------------------
USAGE


-Users can register as donors or donation sites.

-Donors can:

   Check eligibility status
   
   View blood shortages
   
   Book donation appointments
   
-Donation sites can:

   Manage blood inventory
   
   View and manage donor bookings
   
-Vital signs are collected in real time via the IoT wristband.

-Appointment rules prevent multiple active bookings per donor.

-----------------------------------------
FEATURES


-Donor registration and authentication

-Role-based access (donor / donation site)

-Wearable vital-sign integration

-Appointment scheduling system

-Blood shortage indicators

-Blood inventory management

-Real-time synchronization using Firebase

-----------------------------------------

PROJECT STRUCTURE



-Mobile App: Flutter (Android)

-Backend & Sync: Firebase

-Hardware: ESP32 & MAX30100

-Design: Custom 3D-printed enclosure


-----------------------------------------
CONTRIBUTION



This project was developed as a graduation project.

Contributions and updates are coordinated directly with the development team and are not currently open to public pull requests.


-----------------------------------------
LICENSE



This project is licensed under the MIT License.

See the LICENSE file for details.
