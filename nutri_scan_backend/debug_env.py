from dotenv import load_dotenv
import os
from config import Config

print(f"Current Working Directory: {os.getcwd()}")
print(f"Files in current directory: {os.listdir('.')}")

env_path = os.path.join(os.getcwd(), '.env')
print(f"Checking .env at: {env_path}")

if os.path.exists(env_path):
    print("File exists. Content:")
    with open(env_path, 'r', encoding='utf-8') as f:
        print(f.read())
else:
    print("File does NOT exist.")

load_dotenv(env_path)

print(f"MONGO_URI from env: {os.getenv('MONGO_URI')}")
print(f"Config.MONGODB_URI: {Config.MONGODB_URI}")
