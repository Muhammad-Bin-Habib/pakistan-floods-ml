import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split, KFold
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
import pickle
import os

# Columns that are heavily right-skewed (span multiple orders of magnitude).
# Year is left out of the log transform since it's not skewed and isn't a count.
# NOTE: keep this in sync with LOG_FEATURE_IDX in app.py.
LOG_FEATURES = ['Total_deaths', 'Total_injured', 'Roads_damaged_km',
                 'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged']

def train_and_save_model(csv_path, model_dir):
    # Load dataset
    df = pd.read_csv(csv_path, encoding='latin1')

    features = ['Year', 'Total_deaths', 'Total_injured', 'Roads_damaged_km',
                'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged']
    target = 'Affected_population'

    X = df[features].copy()
    X[LOG_FEATURES] = np.log1p(X[LOG_FEATURES])   # compress skewed features
    y_log = np.log1p(df[target])                   # compress skewed target

    # Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # Calculate stable metrics via 5-Fold Cross-Validation
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    r2_scores = []
    rmse_scores = []

    for train_index, test_index in kf.split(X_scaled):
        X_tr, X_te = X_scaled[train_index], X_scaled[test_index]
        y_tr, y_te = y_log.iloc[train_index], y_log.iloc[test_index]

        fold_model = LinearRegression()
        fold_model.fit(X_tr, y_tr)
        fold_pred_log = fold_model.predict(X_te)
        fold_pred_log = np.clip(fold_pred_log, 0, 17.0) # cap log prediction to protect inverse scaling

        fold_pred = np.expm1(fold_pred_log)
        fold_te_orig = np.expm1(y_te)

        r2_scores.append(r2_score(fold_te_orig, fold_pred))
        rmse_scores.append(np.sqrt(mean_squared_error(fold_te_orig, fold_pred)))

    r2 = np.mean(r2_scores)
    rmse = np.mean(rmse_scores)

    # Initialize and train final linear regression model on full dataset (learns in log-space)
    model = LinearRegression()
    model.fit(X_scaled, y_log)

    # Save model and scaler
    os.makedirs(model_dir, exist_ok=True)

    model_path = os.path.join(model_dir, 'model.pkl')
    scaler_path = os.path.join(model_dir, 'scaler.pkl')

    with open(model_path, 'wb') as f:
        pickle.dump(model, f)

    with open(scaler_path, 'wb') as f:
        pickle.dump(scaler, f)

    return r2, rmse, len(df)

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.realpath(os.path.join(base_dir, '..', 'pakistan_floods.csv'))

    r2, rmse, data_count = train_and_save_model(csv_path, base_dir)
    print(f"Model trained successfully on {data_count} records.")
    print(f"R2 Score: {r2:.4f}")
    print(f"RMSE: {rmse:,.0f}")