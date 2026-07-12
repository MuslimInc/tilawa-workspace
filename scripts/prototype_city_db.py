import os
import sqlite3
import urllib.request
import zipfile

# Download a tiny subset or just mock the process to measure schema size
# Since we can't reliably download and parse a massive file in seconds without risking timeouts, 
# we will generate a mock SQLite database representing the schema to measure overhead.

db_path = 'cities_prototype.db'
if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
c = conn.cursor()

c.execute('''
    CREATE TABLE cities (
        id INTEGER PRIMARY KEY,
        name_en TEXT,
        name_ar TEXT,
        country_code TEXT,
        lat REAL,
        lng REAL,
        timezone TEXT
    )
''')

# Insert 50,000 mock rows to simulate GeoNames cities15000
for i in range(50000):
    c.execute('''
        INSERT INTO cities (name_en, name_ar, country_code, lat, lng, timezone)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (f"City {i}", f"مدينة {i}", "EG", 30.0 + (i*0.0001), 31.0 + (i*0.0001), "Africa/Cairo"))

conn.commit()

# Vacuum to optimize
c.execute('VACUUM')
conn.close()

raw_size = os.path.getsize(db_path)
print(f"Raw SQLite DB Size: {raw_size / 1024 / 1024:.2f} MB")

# Compress it to simulate APK contribution
import gzip
with open(db_path, 'rb') as f_in:
    with gzip.open(db_path + '.gz', 'wb') as f_out:
        f_out.writelines(f_in)

comp_size = os.path.getsize(db_path + '.gz')
print(f"Compressed Size (APK contribution): {comp_size / 1024 / 1024:.2f} MB")

# Query latency test
import time
conn = sqlite3.connect(db_path)
c = conn.cursor()

start = time.time()
c.execute('SELECT * FROM cities WHERE name_en LIKE ? LIMIT 10', ('City 45000%',))
res = c.fetchall()
end = time.time()

print(f"Query Latency (English): {(end - start) * 1000:.2f} ms")

start = time.time()
c.execute('SELECT * FROM cities WHERE name_ar LIKE ? LIMIT 10', ('مدينة 45000%',))
res = c.fetchall()
end = time.time()

print(f"Query Latency (Arabic): {(end - start) * 1000:.2f} ms")

conn.close()
