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
pakistan-floods-ml/
│
├── pakistan_floods_analysis.ipynb   # Main analysis notebook
├── pakistan_floods.csv              # Dataset
└── README.md                        # Project documentation
---

## 🚀 How to Run

1. Clone the repository:
```bash
git clone https://github.com/[your-username]/pakistan-floods-ml.git
```

2. Install dependencies:
```bash
pip install pandas numpy scikit-learn matplotlib seaborn jupyter
```

3. Open the notebook:
```bash
jupyter notebook pakistan_floods_analysis.ipynb
```

---

## 📈 Results

### Province Risk Ranking
| Rank | Province | Avg Predicted Affected |
|---|---|---|
| 1 | Sindh | 7,011,663 |
| 2 | KP | 3,462,768 |
| 3 | Punjab | 3,822,106 |
| 4 | Balochistan | 1,856,430 |
| 5 | AJ&K | 846,987 |
| 6 | GB | 67,905 |
| 7 | ICT | 0 |

### Model Performance
| Metric | Value |
|---|---|
| R² Score | 0.6319 |
| RMSE | 1,380,902 |

---

## 👤 Author

**Muhammad Bin Habib**  
(https://www.linkedin.com/in/muhammad-bin-habib-8458bb263/)  


---

## 📝 Note

This is a learning project built to practice end-to-end ML pipeline 
development. The dataset combines official 2022 NDMA records with 
historically proportional estimates for earlier years.
