import sys
import os
from database import db

# Add current directory to path so imports work
sys.path.append(os.getcwd())

try:
    print("Testing Database Connection...")
    # Trigger connection
    if db.db is not None:
        print("SUCCESS: Database object initialized.")
        print(f"Target DB: {db.db.name}")
    else:
        print("FAILURE: Database object is None.")
        
except Exception as e:
    print(f"ERROR: {e}")
