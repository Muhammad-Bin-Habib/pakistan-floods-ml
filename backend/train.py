import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
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

    # Train test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y_log, test_size=0.2, random_state=42)

    # Initialize and train linear regression model (learns in log-space)
    model = LinearRegression()
    model.fit(X_train, y_train)
    y_pred_log = model.predict(X_test)

    # Convert predictions back to real-world scale before scoring, so R2/RMSE
    # stay meaningful in terms of actual affected-population numbers.
    y_pred = np.expm1(y_pred_log)
    y_test_orig = np.expm1(y_test)

    r2 = r2_score(y_test_orig, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test_orig, y_pred))

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