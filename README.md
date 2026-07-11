# pakistan-floods-ml
Linear Regression model predicting flood affected populations across Pakistani provinces (2010–2022)
# 🌊 Pakistan Floods — Linear Regression Analysis

Predicting flood-affected populations across Pakistani provinces using 
machine learning, and projecting future risk through 2030.

---

## 📌 Project Overview

Pakistan is one of the world's most flood-prone countries. The 2022 
mega-flood alone affected over 33 million people and caused $40 billion 
in damages. This project applies Linear Regression to historical flood 
data (2010–2022) across 7 provinces to:

- Identify which features most strongly predict affected population
- Rank provinces by flood risk
- Project future damage trends through 2030

---

## 📊 Key Findings

- **Sindh** is the highest-risk province — 14.5M people affected in 2022
- **KP** ranks 2nd with 4.35M affected in 2022
- **Houses damaged** and **Roads damaged (km)** are the strongest predictors
- Model achieves **R² = [your value]** on test data
- Projected affected population reaches **[X] million** by 2030 under 
  a 3% annual damage growth scenario

---

## 🗂️ Dataset

- 84 rows — 7 provinces × 12 flood years (2010–2022)
- Source: NDMA (National Disaster Management Authority) Pakistan
- 2022 values are from official NDMA records; earlier years estimated 
  proportionally from historical reports

**Features used:**
| Feature | Description |
|---|---|
| Year | Flood year |
| Total_deaths | Total fatalities |
| Total_injured | Total injuries |
| Roads_damaged_km | Road infrastructure damage |
| Bridges_damaged | Number of bridges damaged |
| Houses_damaged | Residential damage |
| Livestock_damaged | Agricultural/livestock loss |

**Target variable:** `Affected_population`

---

## 🛠️ Tools & Libraries

- Python 3.x
- Jupyter Notebook
- Pandas
- NumPy
- Scikit-learn
- Matplotlib
- Seaborn

---

## 📁 Repository Structure

```
pakistan-floods-ml/
│
├── PakFloods.ipynb                  # Main Jupyter Notebook analysis
├── pakistan_floods.csv              # Dataset (updates dynamically via app reports)
├── run_project.bat                  # Unified double-click launcher
├── backend/                         # Flask API backend service
│   ├── app.py                       # API endpoints (predict, retrain, projections, alerts)
│   ├── train.py                     # Model training & serialization script (pickle)
│   ├── model.pkl                    # Trained Linear Regression model artifact
│   ├── scaler.pkl                   # Trained feature scaler artifact
│   └── requirements.txt             # Python dependencies
└── pakistan_floods_app/             # Flutter mobile application
    ├── lib/                         # App codebase
    │   ├── main.dart                # App configuration & setup
    │   ├── models/
    │   │   └── app_state.dart       # App-wide global singleton state
    │   ├── services/
    │   │   └── api_service.dart     # HTTP connection mapping to backend
    │   └── screens/
    │       ├── splash_screen.dart        # Brand and entry splash with NDMA theme transition
    │       ├── login_screen.dart         # Secure credentials login for EOC administrators
    │       ├── analyst_shell.dart        # Main workspace container hosting operational tabs
    │       ├── analyst_overview_tab.dart # EOC Dashboard showing live emergency metrics
    │       ├── analyst_simulation_tab.dart # Tweak precise metrics (bridges, roads) for predictions
    │       ├── analyst_ingestion_tab.dart # Add regional reports & check retraining performance
    │       ├── analyst_trends_tab.dart   # fl_chart charts, timelines & regional report Exporters
    │       └── analyst_settings_tab.dart # Secure officer profile credentials (EOC) & email/download logs
    ├── utils/
    │   ├── file_helper.dart              # Cross-platform downloads dispatcher (Web / Mobile)
    │   ├── file_helper_web.dart          # Web-specific Blob anchor download triggers
    │   └── file_helper_stub.dart         # Platform compilation abstraction stubs
    └── pubspec.yaml                      # Flutter packages (http, fl_chart, file_picker, etc.)
```

---

## 🎯 NDMA EOC Analyst Workspace Features

- **Administrative EOC Board**: Unified operational dashboard showing critical alerts, livestock casualties, housing destruction, and hotlines links.
- **Secure Officer Session Identification**: Set name, batch ID, station, and verified email. Updates update the app synchronously.
- **Cross-Platform Native Downloads**: Interactive buttons export regional CSV logs directly into the device's downloads folder or triggers native browser file saves on Web.
- **Auto-Email Dispatch System (with SMTP Sandbox)**: Email telemetry documents and regional risk tables straight from the app to the EOC officer's destination address.
- **Interactive Calamity Simulator**: Slide bridges, road damages, and casualties to calculate expected displacements.
- **Visual Province Risk Timelines (2023–2030)**: Live province-specific risk chart powered by `fl_chart`.
- **Field Data Ingestion & Live Retraining**: Submit storm telemetry report sets. The app re-runs standard training models and updates R² and RMSE constants instantly.

---

## 🚀 How to Run the Unified App

For the easiest setup on Windows:
1. Double-click the **`run_project.bat`** file in the root directory.
2. The script will install Python requirements, run the Flask backend service, download Flutter packages, and deploy the app.
3. Alternately, you can run the services manually:

### 1. Manual Backend setup:
```bash
# Install dependencies
pip install -r backend/requirements.txt

# Start Flask local API server
python backend/app.py
```

### 2. Manual Flutter launching:
```bash
cd pakistan_floods_app
flutter pub get

# To run on a connected app emulator/physical device:
flutter run

# To run in your Google Chrome browser:
flutter run -d chrome
```

---

## 👤 Author

**Muhammad Bin Habib**  
- [LinkedIn Profile](https://www.linkedin.com/in/muhammad-bin-habib-8458bb263/)

---

## 📝 Project Context

This disaster response mobile prototype is built to expand the historical NDMA predictive model into a collaborative disaster response platform. Real-time reports actively update the CSV dataset and retrain model boundaries automatically.
