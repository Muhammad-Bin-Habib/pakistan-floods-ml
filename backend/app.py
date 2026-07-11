# pyrefly: ignore [missing-import]
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import pandas as pd
# pyrefly: ignore [missing-import]
import numpy as np
import pickle
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from train import train_and_save_model
from pdf_generator import generate_projection_pdf, generate_dataset_summary_pdf

# Load local .env variables if present (for Windows/local startup bypass)
def load_dotenv_fallback():
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, val = line.split('=', 1)
                        os.environ[key.strip()] = val.strip().strip('"').strip("'")

load_dotenv_fallback()

print("==========================================")
print(f"SMTP CONFIG DIAGNOSTIC:")
print(f"  SMTP_USER: {os.environ.get('SMTP_USER')}")
print(f"  SMTP_PASS presents: {bool(os.environ.get('SMTP_PASS'))}")
print("==========================================")

app = Flask(__name__)
# Enable CORS for all routes so mobile/web app can communicate
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.realpath(os.path.join(BASE_DIR, '..', 'pakistan_floods.csv'))
MODEL_PATH = os.path.join(BASE_DIR, 'model.pkl')
SCALER_PATH = os.path.join(BASE_DIR, 'scaler.pkl')

# Feature order used everywhere a raw input list is built for the model.
# Must match the `features` list in train.py.
FEATURES = ['Year', 'Total_deaths', 'Total_injured', 'Roads_damaged_km',
            'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged']

# Indices (within FEATURES/inputs lists) of the columns that train.py log-transforms.
# Year is excluded - see train.py for why.
LOG_FEATURE_IDX = [1, 2, 3, 4, 5, 6]

# Global cache for training metrics
metrics_cache = {
    "r2": None,
    "rmse": None
}


def apply_log_transform(inputs):
    """Log1p-transform the skewed features in a raw input list, matching train.py."""
    transformed = list(inputs)
    for i in LOG_FEATURE_IDX:
        transformed[i] = float(np.log1p(transformed[i]))
    return transformed


def predict_from_inputs(inputs, scaler, model):
    """
    Take a raw (untransformed) feature list in FEATURES order, apply the same
    log1p transform used at training time, scale it, predict in log-space,
    then invert back to real-world affected-population units.
    """
    inputs_log = apply_log_transform(inputs)
    scaled = scaler.transform([inputs_log])
    prediction_log = model.predict(scaled)[0]
    prediction = float(np.expm1(prediction_log))
    return max(0.0, prediction)


def load_or_train_model():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        print("Model or scaler not found. Running training...")
        r2, rmse, _ = train_and_save_model(CSV_PATH, BASE_DIR)
        metrics_cache["r2"] = r2
        metrics_cache["rmse"] = rmse
    elif metrics_cache["r2"] is None:
        # Load once and calculate initial test metrics if training was done outside
        try:
            r2, rmse, _ = train_and_save_model(CSV_PATH, BASE_DIR)
            metrics_cache["r2"] = r2
            metrics_cache["rmse"] = rmse
        except Exception as e:
            print(f"Error doing initial training: {e}")


@app.route('/api/stats', methods=['GET'])
def get_stats():
    try:
        df = pd.read_csv(CSV_PATH, encoding='latin1')

        # Calculate stats
        total_records = len(df)
        avg_deaths = float(df['Total_deaths'].mean())
        avg_injured = float(df['Total_injured'].mean())
        avg_houses = float(df['Houses_damaged'].mean())

        # Find highest risk region by average affected population
        region_avg = df.groupby('Region')['Affected_population'].mean()
        highest_risk_region = region_avg.idxmax()
        highest_risk_val = float(region_avg.max())

        load_or_train_model()

        return jsonify({
            'success': True,
            'total_records': total_records,
            'avg_deaths': round(avg_deaths, 2),
            'avg_injured': round(avg_injured, 2),
            'avg_houses': round(avg_houses, 2),
            'highest_risk_region': highest_risk_region,
            'highest_risk_avg_affected': round(highest_risk_val, 2),
            'model_metrics': {
                'r2': round(metrics_cache["r2"], 4) if metrics_cache["r2"] is not None else 0.6319,
                'rmse': round(metrics_cache["rmse"], 2) if metrics_cache["rmse"] is not None else 1380902.0
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/regions', methods=['GET'])
def get_regions():
    try:
        df = pd.read_csv(CSV_PATH, encoding='latin1')
        regions = sorted(df['Region'].dropna().unique().tolist())
        return jsonify({'success': True, 'regions': regions})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No input data provided'}), 400

        required_fields = ['Year', 'Total_deaths', 'Total_injured', 'Roads_damaged_km',
                           'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged']

        missing = [f for f in required_fields if f not in data]
        if missing:
            return jsonify({'success': False, 'message': f'Missing fields: {missing}'}), 400

        # Parse inputs in FEATURES order
        inputs = [float(data[f]) for f in FEATURES]

        # Load scaler and model
        load_or_train_model()
        with open(SCALER_PATH, 'rb') as f:
            scaler = pickle.load(f)
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)

        # Log-transform, scale, predict, and invert back to real units
        prediction = predict_from_inputs(inputs, scaler, model)

        return jsonify({
            'success': True,
            'predicted_affected_population': round(prediction, 2)
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/report', methods=['POST'])
def report_disaster():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No input data provided'}), 400

        required_fields = ['Region', 'Year', 'Total_deaths', 'Total_injured', 'Roads_damaged_km',
                           'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged', 'Affected_population']

        missing = [f for f in required_fields if f not in data]
        if missing:
            return jsonify({'success': False, 'message': f'Missing fields: {missing}'}), 400

        # Prepare row details, map schema
        new_row = {
            'Region': str(data['Region']),
            'Year': int(data['Year']),
            'Total_deaths': int(data['Total_deaths']),
            'M_D': int(data.get('M_D', int(data['Total_deaths']) // 2)),
            'F_D': int(data.get('F_D', int(data['Total_deaths']) // 3)),
            'C_D': int(data.get('C_D', int(data['Total_deaths']) // 6)),
            'Total_injured': int(data['Total_injured']),
            'M_I': int(data.get('M_I', int(data['Total_injured']) // 2)),
            'F_I': int(data.get('F_I', int(data['Total_injured']) // 3)),
            'C_I': int(data.get('C_I', int(data['Total_injured']) // 6)),
            'Roads_damaged_km': float(data['Roads_damaged_km']),
            'Bridges_damaged': int(data['Bridges_damaged']),
            'Houses_damaged': int(data['Houses_damaged']),
            'Livestock_damaged': int(data['Livestock_damaged']),
            'Affected_population': int(data['Affected_population'])
        }

        # Load and append dynamically to dataset
        df = pd.read_csv(CSV_PATH, encoding='latin1')
        df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
        df.to_csv(CSV_PATH, index=False)

        # Train model asynchronously/inline on report
        r2, rmse, data_count = train_and_save_model(CSV_PATH, BASE_DIR)
        metrics_cache["r2"] = r2
        metrics_cache["rmse"] = rmse

        return jsonify({
            'success': True,
            'message': 'Disaster reported successfully and stored in dataset.',
            'new_total_records': data_count,
            'model_updated': True,
            'new_metrics': {
                'r2': round(r2, 4),
                'rmse': round(rmse, 2)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/retrain', methods=['POST'])
def force_retrain():
    try:
        r2, rmse, data_count = train_and_save_model(CSV_PATH, BASE_DIR)
        metrics_cache["r2"] = r2
        metrics_cache["rmse"] = rmse
        return jsonify({
            'success': True,
            'message': 'Model retrained successfully.',
            'total_records': data_count,
            'metrics': {
                'r2': round(r2, 4),
                'rmse': round(rmse, 2)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


def build_future_rows(baseline, future_years):
    """Shared helper: build the 3%/yr growth-scenario rows used by projections/report/email."""
    future_rows = []
    for i, yr in enumerate(future_years):
        scale = 1 + (i * 0.03)  # 3% annual growth scenario
        future_rows.append({
            'Year': yr,
            'Total_deaths': int(baseline['Total_deaths'] * scale),
            'Total_injured': int(baseline['Total_injured'] * scale),
            'Roads_damaged_km': float(baseline['Roads_damaged_km'] * scale),
            'Bridges_damaged': int(baseline['Bridges_damaged'] * scale),
            'Houses_damaged': int(baseline['Houses_damaged'] * scale),
            'Livestock_damaged': int(baseline['Livestock_damaged'] * scale),
        })
    return future_rows


@app.route('/api/projections', methods=['GET'])
def get_projections():
    region = request.args.get('region', 'Sindh')
    try:
        df = pd.read_csv(CSV_PATH, encoding='latin1')
        region_data = df[df['Region'].str.lower() == region.lower()]

        if region_data.empty:
            # Fallback to Sindh if requested region not found
            region_data = df[df['Region'].str.lower() == 'sindh']
            if region_data.empty:
                return jsonify({'success': False, 'message': f'Region {region} or fallback Sindh not found in data'}), 404

        baseline = region_data.sort_values('Year').iloc[-1]

        future_years = list(range(2023, 2031))
        future_rows = build_future_rows(baseline, future_years)
        future_df = pd.DataFrame(future_rows)

        load_or_train_model()
        with open(SCALER_PATH, 'rb') as f:
            scaler = pickle.load(f)
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)

        projections_list = []
        for idx, row in future_df.iterrows():
            inputs = [row[f] for f in FEATURES]
            pred = predict_from_inputs(inputs, scaler, model)
            projections_list.append({
                'year': int(row['Year']),
                'predicted_affected': round(pred, 2),
                'estimated_deaths': int(row['Total_deaths']),
                'estimated_injured': int(row['Total_injured']),
                'estimated_houses_damaged': int(row['Houses_damaged'])
            })

        return jsonify({
            'success': True,
            'region': baseline['Region'],
            'projections': projections_list
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/alerts', methods=['GET'])
def get_alerts():
    # Return mock disaster alerts which are highly dynamic and informative
    alerts = [
        {
            'id': 'alert_1',
            'type': 'Flood warning',
            'severity': 'RED',
            'location': 'Sindh (Indus River Basin)',
            'description': 'High discharge flowing past Sukkur Barrage. Nearby coastal villages are advised to evacuate immediately.',
            'time': 'Just Now'
        },
        {
            'id': 'alert_2',
            'type': 'Earthquake warning',
            'severity': 'YELLOW',
            'location': 'Khyber Pakhtunkhwa (KP) & Northern Areas',
            'description': 'Minor tremors (magnitude 4.2) reported around Hindu Kush region. Stay away from old buildings.',
            'time': '2 hours ago'
        },
        {
            'id': 'alert_3',
            'type': 'Weather Update',
            'severity': 'ORANGE',
            'location': 'Balochistan (Gawadar, Kech)',
            'description': 'Unusually heavy monsoon rainfall expected in coastal Balochistan within next 24 hours. Prepare emergency kits.',
            'time': '5 hours ago'
        }
    ]
    return jsonify({
        'success': True,
        'alerts': alerts
    })


@app.route('/api/exports/dataset', methods=['GET'])
def export_dataset():
    try:
        if os.path.exists(CSV_PATH):
            return send_file(CSV_PATH, mimetype='text/csv', as_attachment=True, download_name='pakistan_floods_updated.csv')
        else:
            return jsonify({'success': False, 'message': 'Dataset file not found'}), 404
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/imports/dataset', methods=['POST'])
def import_dataset():
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'message': 'No file segment found'}), 400

        file = request.files['file']
        if not file.filename.endswith('.csv'):
            return jsonify({'success': False, 'message': 'Only CSV files are allowed'}), 400

        df = pd.read_csv(file, encoding='latin1')
        required_cols = ['Region', 'Year', 'Total_deaths', 'Total_injured', 'Roads_damaged_km',
                        'Bridges_damaged', 'Houses_damaged', 'Livestock_damaged', 'Affected_population']

        missing = [c for c in required_cols if c not in df.columns]
        if missing:
            return jsonify({'success': False, 'message': f'CSV missing required columns: {missing}'}), 400

        df.to_csv(CSV_PATH, index=False)

        r2, rmse, data_count = train_and_save_model(CSV_PATH, BASE_DIR)
        metrics_cache["r2"] = r2
        metrics_cache["rmse"] = rmse

        return jsonify({
            'success': True,
            'message': 'Custom dataset imported and calibration metrics updated successfully!',
            'total_records': data_count,
            'metrics': {
                'r2': round(r2, 4),
                'rmse': round(rmse, 2)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/exports/report', methods=['GET'])
def export_report():
    region = request.args.get('region', 'Sindh')
    try:
        df = pd.read_csv(CSV_PATH, encoding='latin1')
        region_data = df[df['Region'].str.lower() == region.lower()]
        if region_data.empty:
            region_data = df[df['Region'].str.lower() == 'sindh']
            if region_data.empty:
                return jsonify({'success': False, 'message': f'Region {region} not found.'}), 404

        baseline = region_data.sort_values('Year').iloc[-1]

        future_years = list(range(2023, 2031))
        rows = []

        load_or_train_model()
        with open(SCALER_PATH, 'rb') as f:
            scaler = pickle.load(f)
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)

        for i, yr in enumerate(future_years):
            scale = 1 + (i * 0.03)
            inputs = [
                float(yr),
                float(baseline['Total_deaths'] * scale),
                float(baseline['Total_injured'] * scale),
                float(baseline['Roads_damaged_km'] * scale),
                float(baseline['Bridges_damaged'] * scale),
                float(baseline['Houses_damaged'] * scale),
                float(baseline['Livestock_damaged'] * scale)
            ]
            pred = predict_from_inputs(inputs, scaler, model)

            min_aff = round(pred * 0.85)
            max_aff = round(pred * 1.15)

            rows.append({
                'Region': baseline['Region'],
                'Year': yr,
                'Proj_Fatalities': round(baseline['Total_deaths'] * scale),
                'Proj_Injured': round(baseline['Total_injured'] * scale),
                'Proj_Roads_Damaged_km': round(baseline['Roads_damaged_km'] * scale, 1),
                'Proj_Bridges_Damaged': round(baseline['Bridges_damaged'] * scale),
                'Proj_Houses_Damaged': round(baseline['Houses_damaged'] * scale),
                'Proj_Livestock_Lost': round(baseline['Livestock_damaged'] * scale),
                'Est_Affected_Min': min_aff,
                'Est_Affected_Max': max_aff,
                'Tents_Req_Min': round(min_aff / 6.0),
                'Tents_Req_Max': round(max_aff / 6.0),
                'Water_Liters_Min': round(min_aff * 15),
                'Water_Liters_Max': round(max_aff * 15),
                'MedicalComps_Req_Min': round(min_aff / 80.0),
                'MedicalComps_Req_Max': round(max_aff / 80.0)
            })

        report_df = pd.DataFrame(rows)
        report_csv_path = os.path.join(BASE_DIR, f'{region}_flood_projections_report.csv')
        report_df.to_csv(report_csv_path, index=False)

        return send_file(report_csv_path, mimetype='text/csv', as_attachment=True, download_name=f'{region}_projections_report.csv')
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


def send_email_with_attachment(to_email, subject, body, file_path, file_name):
    # Read environment config setup
    load_dotenv_fallback()

    smtp_server = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
    smtp_port = int(os.environ.get('SMTP_PORT', '587'))
    smtp_user = os.environ.get('SMTP_USER', '')
    smtp_pass = os.environ.get('SMTP_PASS', '')

    print(f"[SMTP DISPATCH] Attempting send - user: {smtp_user}, pass length: {len(smtp_pass) if smtp_pass else 0}")

    # Sandbox/Test harness console fallback is activated when credentials are blank
    if not smtp_user or not smtp_pass:
        print("=" * 60)
        print("[EMAIL] [SANDBOX SYSTEM EMAIL DISPATCH SIMULATION]")
        print(f"TO:      {to_email}")
        print(f"SUBJECT: {subject}")
        print(f"FILE:    {file_name} ({file_path})")
        print("-" * 60)
        print(body)
        print("=" * 60)
        return True, "Email generated. Simulation Mode Active: Check Flask console output."

    try:
        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        with open(file_path, 'rb') as f:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(f.read())
            encoders.encode_base64(part)
            part.add_header('Content-Disposition', f'attachment; filename="{file_name}"')
            msg.attach(part)

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(smtp_user, to_email, msg.as_string())

        return True, "Email successfully transmitted via SMTP server!"
    except Exception as e:
        return False, f"SMTP transmission failure: {str(e)}"


@app.route('/api/exports/email', methods=['POST'])
def email_export():
    try:
        data = request.get_json() or {}
        to_email = data.get('email')
        export_type = data.get('type') # 'dataset' or 'report'
        region = data.get('region', 'Sindh')
        officer_name = data.get('officer_name', 'EOC Officer')
        batch_id = data.get('batch_id', 'EOC-UNKNOWN')
        file_format = data.get('format', 'csv') # 'csv' or 'pdf'

        if not to_email:
            return jsonify({'success': False, 'message': 'Missing recipient email address'}), 400

        file_path = None
        file_name = None

        if export_type == 'dataset':
            if file_format == 'pdf':
                file_path = os.path.join(BASE_DIR, 'pakistan_floods_telemetry_summary.pdf')
                df_historical = pd.read_csv(CSV_PATH, encoding='latin1')
                generate_dataset_summary_pdf(officer_name, batch_id, df_historical, file_path)
                file_name = 'pakistan_floods_telemetry_summary.pdf'
            else:
                file_path = CSV_PATH
                file_name = 'pakistan_floods_updated.csv'
            subject = 'FloodGuard Telemetry Database System Dispatch'
            body = (
                f"NDMA Emergency Command Center Alert\n"
                f"--------------------------------------------------\n"
                f"Officer: {officer_name}\n"
                f"Batch ID: {batch_id}\n\n"
                f"This email contains the requested dynamic telemetry database update ({file_format.upper()}) "
                f"from the central FloodGuard simulation command node.\n\n"
                f"Respectfully,\nEOC Automated Disaster Intelligence Dispatch"
            )
        elif export_type == 'report':
            df = pd.read_csv(CSV_PATH, encoding='latin1')
            region_data = df[df['Region'].str.lower() == region.lower()]
            if region_data.empty:
                region_data = df[df['Region'].str.lower() == 'sindh']
                if region_data.empty:
                    return jsonify({'success': False, 'message': f'Region {region} not registered.'}), 404

            baseline = region_data.sort_values('Year').iloc[-1]
            future_years = list(range(2023, 2031))
            rows = []

            load_or_train_model()
            with open(SCALER_PATH, 'rb') as f:
                scaler = pickle.load(f)
            with open(MODEL_PATH, 'rb') as f:
                model = pickle.load(f)

            for i, yr in enumerate(future_years):
                scale = 1 + (i * 0.03)
                inputs = [
                    float(yr),
                    float(baseline['Total_deaths'] * scale),
                    float(baseline['Total_injured'] * scale),
                    float(baseline['Roads_damaged_km'] * scale),
                    float(baseline['Bridges_damaged'] * scale),
                    float(baseline['Houses_damaged'] * scale),
                    float(baseline['Livestock_damaged'] * scale)
                ]
                pred = predict_from_inputs(inputs, scaler, model)

                min_aff = round(pred * 0.85)
                max_aff = round(pred * 1.15)

                rows.append({
                    'Region': baseline['Region'],
                    'Year': yr,
                    'Proj_Fatalities': round(baseline['Total_deaths'] * scale),
                    'Proj_Injured': round(baseline['Total_injured'] * scale),
                    'Proj_Roads_Damaged_km': round(baseline['Roads_damaged_km'] * scale, 1),
                    'Proj_Bridges_Damaged': round(baseline['Bridges_damaged'] * scale),
                    'Proj_Houses_Damaged': round(baseline['Houses_damaged'] * scale),
                    'Proj_Livestock_Lost': round(baseline['Livestock_damaged'] * scale),
                    'Est_Affected_Min': min_aff,
                    'Est_Affected_Max': max_aff,
                    'Tents_Req_Min': round(min_aff / 6.0),
                    'Tents_Req_Max': round(max_aff / 6.0),
                    'Water_Liters_Min': round(min_aff * 15),
                    'Water_Liters_Max': round(max_aff * 15),
                    'MedicalComps_Req_Min': round(min_aff / 80.0),
                    'MedicalComps_Req_Max': round(max_aff / 80.0)
                })

            report_df = pd.DataFrame(rows)

            if file_format == 'pdf':
                load_or_train_model()
                model_r2 = metrics_cache.get('r2') or 0.63
                file_path = os.path.join(BASE_DIR, f'{region}_flood_projections_report.pdf')
                generate_projection_pdf(region, officer_name, batch_id, model_r2, report_df, file_path)
                file_name = f'{region}_projections_report.pdf'
            else:
                file_path = os.path.join(BASE_DIR, f'{region}_flood_projections_report.csv')
                report_df.to_csv(file_path, index=False)
                file_name = f'{region}_projections_report.csv'

            subject = f'FloodGuard Regional Risk Projections: {region.upper()}'
            body = (
                f"NDMA Emergency Command Center Alert\n"
                f"--------------------------------------------------\n"
                f"Officer: {officer_name}\n"
                f"Batch ID: {batch_id}\n"
                f"Assessment Target: {region.upper()} (2023-2030)\n"
                f"File Format: {file_format.upper()}\n\n"
                f"This email contains the requested regional calamity risk and relief material projections report "
                f"for the territory of {region.upper()}.\n\n"
                f"Respectfully,\nEOC Automated Disaster Intelligence Dispatch"
            )
        else:
            return jsonify({'success': False, 'message': 'Unknown export type'}), 400

        success, message = send_email_with_attachment(to_email, subject, body, file_path, file_name)

        # Clean up temporary generated files
        if file_path and os.path.exists(file_path):
            if file_format == 'pdf' or export_type == 'report':
                try:
                    os.remove(file_path)
                except:
                    pass

        return jsonify({'success': success, 'message': message})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


if __name__ == '__main__':
    load_or_train_model()
    # Run server locally on all interfaces at port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)