import time
from typing import List
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from google.oauth2 import id_token
from google.auth.transport import requests
from models import UserRole
import os

SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "SUPER_SECRET_KEY_FOR_JWT")
ALGORITHM = "HS256"

# User configured Google Client ID
GOOGLE_CLIENT_ID = os.environ.get("GOOGLE_CLIENT_ID", "YOUR_GOOGLE_CLIENT_ID")

security = HTTPBearer()

def create_access_token(user_id: str, role: str):
    payload = {
        "sub": user_id,
        "role": role,
        "exp": time.time() + (24 * 3600)  # 24 hour expiry
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

def require_role(allowed_roles: List[UserRole]):
    def role_checker(current_user: dict = Depends(get_current_user)):
        user_role = current_user.get("role")
        if user_role not in [role.value for role in allowed_roles]:
            raise HTTPException(status_code=403, detail="Not authorized to perform this action")
        return current_user
    return role_checker

def verify_google_token(token: str):
    try:
        # Specify the CLIENT_ID of the app that accesses the backend:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        return idinfo
    except ValueError:
        # Invalid token
        raise HTTPException(status_code=401, detail="Invalid Google token")
