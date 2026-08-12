"""
Production Management System — Pydantic Models
Request/response schemas for the FastAPI backend.
"""

from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel


# ─── Enums ─────────────────────────────────────────────────────────────────────

class UserRole(str, Enum):
    Operator = "Operator"
    ShiftEngineer = "Shift Engineer"
    Admin = "Admin"


class NotificationType(str, Enum):
    NewRouteCardAssigned = "New Route Card Assigned"
    AdminActionRequired = "Admin Action Required"
    StepSignedOff = "Step Signed Off"
    DeviationFlagged = "Deviation Flagged"
    DeviationResolved = "Deviation Resolved"
    DateMismatchAlert = "Date Mismatch Alert"
    IQCFailed = "IQC Failed"
    General = "General"


class ProcessType(str, Enum):
    IQC = "iqc"
    RM_CUTTING = "rm_cutting"
    MACHINING = "machining"
    DEBURRING = "deburring"
    LASER_MARKING = "laser_marking"
    SPECIAL_PROCESS = "special_process"
    QC = "qc"


class RiskLevel(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class AlertType(str, Enum):
    OVERDUE_PROCESS = "OVERDUE_PROCESS"
    SEQUENCE_VIOLATION = "SEQUENCE_VIOLATION"
    STALE_WIP = "STALE_WIP"
    MISSING_DATE = "MISSING_DATE"


# ─── Auth ──────────────────────────────────────────────────────────────────────

class SignupRequest(BaseModel):
    name: str
    email: str
    password: str
    role: Optional[UserRole] = UserRole.Operator

class LoginWithPasswordRequest(BaseModel):
    email: str
    password: str

class GoogleLoginRequest(BaseModel):
    idToken: str
    role: Optional[UserRole] = None

class ForgotPasswordRequest(BaseModel):
    email: str

class VerifyOTPRequest(BaseModel):
    email: str
    otp: str

class ResetPasswordRequest(BaseModel):
    email: str
    otp: str
    newPassword: str

class LoginResponse(BaseModel):
    success: bool
    user: dict


# ─── Route Card Creation ──────────────────────────────────────────────────────

class StepData(BaseModel):
    stepNumber: Optional[int] = None
    operationName: str
    workCenter: Optional[str] = "WIP"
    instructions: str
    requiredSop: Optional[str] = "SOP-GEN-01"
    processKey: Optional[str] = None


class CreateCardRequest(BaseModel):
    jobName: str
    partNumber: str
    partRevision: Optional[str] = "A"
    batchQuantity: int
    workOrderNumber: str
    koNumber: str  # Required field — all parts grouped under same KO
    notes: Optional[str] = ""
    createdBy: Optional[str] = "System Creator"
    userId: Optional[str] = None
    userEmail: Optional[str] = None
    steps: Optional[List[StepData]] = None  # Optional — auto-generated from 7 standard processes if not provided
    riskLevel: Optional[RiskLevel] = None
    complexity: Optional[str] = None
    targetDate: Optional[str] = None


# ─── Step Actions ─────────────────────────────────────────────────────────────

class SignOffRequest(BaseModel):
    operatorName: str
    operatorRole: UserRole
    remarks: Optional[str] = ""
    userId: Optional[str] = None
    userEmail: Optional[str] = None
    completionQty: Optional[int] = None


class DeviationRequest(BaseModel):
    reason: str
    remarks: Optional[str] = ""
    operatorName: Optional[str] = None
    userId: Optional[str] = None
    userEmail: Optional[str] = None


class ResolveRequest(BaseModel):
    remarks: str
    engineerName: str
    userId: Optional[str] = None


class IQCFailRequest(BaseModel):
    """Request to mark IQC as failed — triggers reject/return to vendor flow."""
    reason: str
    remarks: Optional[str] = ""
    operatorName: Optional[str] = None
    userId: Optional[str] = None
    userEmail: Optional[str] = None


class IQCReinspectRequest(BaseModel):
    """Request to re-inspect after vendor return."""
    remarks: Optional[str] = ""
    operatorName: Optional[str] = None
    userId: Optional[str] = None
    userEmail: Optional[str] = None


# ─── User Preferences / Notifications ─────────────────────────────────────────

class UpdatePreferencesRequest(BaseModel):
    emailNotifications: Optional[bool] = None
    pushNotifications: Optional[bool] = None
    smsNotifications: Optional[bool] = None
    darkMode: Optional[bool] = None
    language: Optional[str] = None


class SimulateNotifRequest(BaseModel):
    title: str
    message: str
    type: NotificationType = NotificationType.General

class BulkCreateRequest(BaseModel):
    koNumber: str
    bomNumber: str
    items: List[Dict[str, Any]]
