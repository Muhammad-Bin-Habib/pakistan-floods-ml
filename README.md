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
    │       ├── splash_screen.dart   # Brand and entry splash with transition
    │       ├── onboarding_screen.dart # Interactive multi-page core highlights
    │       ├── login_screen.dart    # Split portal for Citizens and Government Officials
    │       ├── register_screen.dart # Profile signup for new citizens
    │       ├── citizen_home.dart    # Home shell managing 5 bottom navigation tabs
    │       ├── home_screen.dart     # Dynamic home dashboard, alert ribbons, quick dialers
    │       ├── zones_screen.dart    # Region-wise Danger (Red/Orange) vs Safe (Green) zones
    │       ├── safety_guide_screen.dart # Categorized Do's & Don'ts (Flood, Earthquakes, Landslides)
    │       ├── prediction_screen.dart # Slider-based friendly flood impact estimator
    │       ├── profile_screen.dart  # Manage contacts, access SOS portal and data contribution
    │       ├── sos_screen.dart      # Pulsing SOS emergency warning & rapid response
    │       ├── data_contribution_screen.dart # Citizens-sourced storm reporting
    │       ├── gov_dashboard_screen.dart # NDMA government operations metrics & tech controls
    │       ├── projections_screen.dart # Admin tools: Interactive fl_chart target simulation
    │       ├── report_screen.dart   # Admin tools: Manual dataset appending & model tuning
    │       └── predictor_screen.dart # Admin tools: Custom ML variable playground
    └── pubspec.yaml                 # Flutter packages (http, fl_chart, intl)
```

---

## 🎯 Mobile App & Dashboard Features

- **Split-Role Experience**: Dedicated flows for citizens (evacuations, live forecasts, emergency hotlines, rapid SOS) and national government administrators/developers (NDMA hub).
- **Onboarding and Splash Intro**: Fluid walkthrough of features (alerts, safety, predictor) before jumping into registration.
- **Dynamic Connection Management**: Developers can view and update the backend's local server IP (e.g. `10.0.2.2:5000` for Android emulators or machine IP for physical devices) directly in the Tech parameters portal, with offline-resilient fallbacks.
- **Interactive Predictive Analytics**:
  - **Citizen Estimator**: Slide precipitation metrics and choose your province to instantly project population impact.
  - **Developer Stats Playground**: Tweak precise metrics (bridge collapses, livestock casualties, road damage) to see fine-grained model outputs.
- **Risk Projections Timeline (2023–2030)**: Explores projections under the 3% growth model via interactive charts powered by `fl_chart`.
- **Incremental Retraining on New Data**: Submit real-time disaster reports from the field directly. The app appends details to `pakistan_floods.csv` and triggers the Flask backend to retrain the model, displaying updated R² and RMSE coefficients dynamically.
- **Citizen SOS Rapid Response**: Pulsing alarm button submits current profile details to emergency lines together with a safety checklist.
- **NDMA Operational Hub**: View KPI status cards, top priority regions based on high casualties, and retrain ML modules on the fly.
- **Crisis Response & Safety Guidelines**: Integrated NDMA emergency control dials, Rescue 1122, and Edhi services alongside safety protocols for floods, earthquakes and landslides.

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
