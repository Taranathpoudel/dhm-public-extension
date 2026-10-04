import requests
import time
import json
import csv
from datetime import datetime, timezone

def get_sid(session):
    url = f"https://hydrology.gov.np/gss/socket.io/?EIO=3&transport=polling&t={int(time.time()*1000)}"
    res = session.get(url)
    text = res.text
    start_idx = text.find('{')
    if start_idx != -1:
        end_idx = text.rfind('}')
        if end_idx != -1:
            try:
                data = json.loads(text[start_idx:end_idx+1])
                return data.get('sid')
            except json.JSONDecodeError:
                pass
    return None

def fetch_data():
    session = requests.Session()
    sid = get_sid(session)
    if not sid:
        print("Error getting sid")
        return [], []
    
    for evt in ["river_test", "rainfall_watch"]:
        payload = f'42["client_request","{evt}"]'
        session.post(
            f"https://hydrology.gov.np/gss/socket.io/?EIO=3&transport=polling&sid={sid}&t={int(time.time()*1000)}",
            data=f"{len(payload)}:{payload}",
            headers={"Content-Type": "text/plain;charset=UTF-8"}
        )
    
    time.sleep(1.5)
    res = session.get(f"https://hydrology.gov.np/gss/socket.io/?EIO=3&transport=polling&sid={sid}&t={int(time.time()*1000)}")
    
    raw = res.text
    river_data = []
    rainfall_data = []
    
    i = 0
    while i < len(raw):
        colon = raw.find(':')
        if colon == -1: break
        try:
            length = int(raw[:colon])
        except ValueError:
            break
        payload = raw[colon+1:colon+1+length]
        if payload.startswith('42['):
            try:
                parsed = json.loads(payload[2:])
                if parsed[0] in ("river_test", "river_watch"):
                    river_data = parsed[1]
                elif parsed[0] == "rainfall_watch":
                    rainfall_data = parsed[1]
            except Exception as e:
                print("Error parsing", e)
        raw = raw[colon+1+length:]
        
    return river_data, rainfall_data

def process_data(river_data, rainfall_data):
    st_map = {}
    now = datetime.now(timezone.utc)
    
    def parse_time(t_str):
        if not t_str: return None
        try:
            # Example format handled: "2024-10-04T12:00:00+05:45"
            dt = datetime.fromisoformat(t_str.replace("Z", "+00:00"))
            return dt.astimezone(timezone.utc)
        except Exception as e:
            # print(f"Error parsing date {t_str}: {e}")
            return None

    def update_map(items, data_type):
        for item in items:
            sid = item.get('id')
            if not sid: continue
            
            if sid not in st_map:
                st_map[sid] = {
                    'id': sid,
                    'name': item.get('name', ''),
                    'basin': item.get('basin', ''),
                    'district': item.get('district', ''),
                    'delayMinutes': float('inf'),
                    'latestTime': None,
                    'type': data_type
                }
            else:
                st_map[sid]['type'] = "Both"
                
            time_str = None
            if data_type == 'River' and 'waterLevel' in item and item['waterLevel']:
                time_str = item['waterLevel'].get('datetime')
            elif data_type == 'Rainfall' and 'latest_observation' in item and item['latest_observation']:
                time_str = item['latest_observation'].get('datetime')
                
            dt = parse_time(time_str)
            if dt:
                diff = max(0.0, (now - dt).total_seconds() / 60.0)
                if diff < st_map[sid]['delayMinutes']:
                    st_map[sid]['delayMinutes'] = diff
                    st_map[sid]['latestTime'] = time_str

    update_map(river_data, 'River')
    update_map(rainfall_data, 'Rainfall')
    
    filtered = []
    for s in st_map.values():
        delay = s['delayMinutes']
        if delay <= 10:
            s['status_category'] = 'On-Time (<= 10m)'
            filtered.append(s)
        elif delay > 60 and delay != float('inf'):
            s['status_category'] = 'Critical (> 1h)'
            filtered.append(s)
            
    filtered.sort(key=lambda x: x['delayMinutes'])
    return filtered

def save_csv(data, filename="dhm_filtered_data.csv"):
    if not data:
        print("No data to save.")
        return
        
    keys = ['id', 'name', 'basin', 'district', 'type', 'status_category', 'delayMinutes', 'latestTime']
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=keys)
        writer.writeheader()
        for row in data:
            row_out = {k: row.get(k, '') for k in keys}
            if row_out['delayMinutes'] != float('inf'):
                row_out['delayMinutes'] = round(row_out['delayMinutes'])
            writer.writerow(row_out)
    print(f"Saved {len(data)} records to {filename}")

if __name__ == "__main__":
    print("Fetching data from DHM...")
    river, rain = fetch_data()
    print(f"Found {len(river)} river records, {len(rain)} rainfall records.")
    processed = process_data(river, rain)
    save_csv(processed)
