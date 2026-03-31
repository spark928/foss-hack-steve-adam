# 🎓 Study Flow: Students Buddy

**Academic Vault** is a high-performance, local-first productivity suite built with Flutter. It is designed to replace fragmented study tools with a single, cohesive ecosystem that respects user privacy and functions entirely offline.

---

## 🛠️ Technical Architecture

The app is built on a **FOSS (Free and Open Source Software)** stack, prioritizing speed and data sovereignty.

* **Database:** [Hive](https://pub.dev/packages/hive) — A lightning-fast NoSQL database used for all persistent data (Timetables, Attendance, Study Stats). 
* **PDF Engine:** `flutter_pdfview` — High-fidelity, in-app document rendering.
* **Analytics:** `fl_chart` — Reactive data visualization for study habits.
* **UI Framework:** Flutter (Material 3) — Google’s latest design system for a fluid, modern experience.

---
## 📺 Project Demo
Watch the **Study Flow** ecosystem in action, featuring the Live Timetable Highlighting, PDF Vault, and Native Time Dial integration.

[![Study Flow Demo](https://img.youtube.com/vi/6BliMVecqSg/0.jpg)](https://youtu.be/6BliMVecqSg)

*Click the image above to watch the full demonstration on YouTube.*

## 🌟 Key Features

### 1. The Study Vault (File Management)
A recursive, folder-based system for academic resources.
* **Subject-Specific Directories:** Automatically organizes files into Chapters, Notes, and PDFs.
* **In-App Viewing:** Open and study PDFs directly within the app to maintain focus.
* **Breadcrumb Navigation:** Deep-dive into complex folder structures without losing your place.

### 2. Live Timetable & Smart Highlighting
A context-aware scheduling engine that knows where you need to be.
* **Native Time Input:** Uses the **Android Material Time Picker** (Clock Dial) for standardized `AM/PM` scheduling.
* **Real-Time Context:** The app compares the system clock with your schedule to provide:
    * **Green Glow Highlight:** Active classes are visually prioritized in the Timetable.
    * **Live Dashboard Badge:** The Academic page instantly flags the current subject for one-tap access.

### 3. Focus Timer & Academic Analytics
Bridge the gap between "planning" and "doing."
* **Deep-Work Timer:** Tracks study sessions per subject.
* **Progress Visualization:** Automatically generates bar charts showing your weekly study distribution.
* **Auto-Persistence:** All session data is committed to the local Hive box immediately upon completion.

### 4. Attendance Tracker
* **Automated Calculations:** Tracks "Total" vs. "Attended" classes.
* **Threshold Alerts:** Visual warnings if attendance drops below the user-defined "Minimum %."

### 5. Mindmap
* **Tree formation:** Help have a structured understanding.

### 6. Flash Cards
* **Easy revision:** Help in revising anytime anywhere.
* **Fun and fast revision:** A fun way to learn and revise topics faster.

### 6. To do list
* **Track task:** Help in tracking your tasks and avoid last minute rush.

* ### 6. Freehand Canvas
* **Simple :** Help in tracking your tasks and avoid last minute rush.


---

## 🚀 Deployment & Build Commands

To ensure a stable demo, use the following commands to bypass file locks and generate a high-speed production APK.

### **Kill Processes & Force Build APK**
```powershell
taskkill /F /IM java.exe /T; taskkill /F /IM dart.exe /T; flutter build apk --split-per-abi --no-shrink --no-pub
