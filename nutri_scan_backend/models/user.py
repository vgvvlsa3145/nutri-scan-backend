from datetime import datetime
from bson import ObjectId

class User:
    @staticmethod
    def create_user(email, password_hash, name):
        return {
            'email': email,
            'password_hash': password_hash,
            'name': name,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }

    @staticmethod
    def to_dict(user):
        if user is None:
            return None
        user['_id'] = str(user['_id'])
        return user
