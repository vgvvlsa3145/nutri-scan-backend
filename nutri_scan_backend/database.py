from pymongo import MongoClient
from config import Config
import os

class Database:
    _instance = None
    _client = None
    _db = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Database, cls).__new__(cls)
            cls._instance._connect()
        return cls._instance

    def _connect(self):
        try:
            self._client = MongoClient(Config.MONGODB_URI)
            self._db = self._client[Config.DATABASE_NAME]
            print(f"Connected to MongoDB: {Config.DATABASE_NAME}")
        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            raise

    @property
    def db(self):
        return self._db

    @property
    def users(self):
        return self._db.users

    @property
    def profiles(self):
        return self._db.profiles

    @property
    def food_logs(self):
        return self._db.food_logs

    @property
    def daily_reports(self):
        return self._db.daily_reports

    @property
    def diet_plans(self):
        return self._db.diet_plans

    def close(self):
        if self._client:
            self._client.close()

# Initialize database connection
db = Database()
