"""
Production Management System — In-Memory Database
"""

import copy, uuid, random
from datetime import datetime, timezone
import bcrypt

def _now():
    return datetime.now(timezone.utc).isoformat()

def _uuid():
    return str(uuid.uuid4())[:8]

def _hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def _check_pw(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

_DEFAULT_HASH = _hash_pw("password123")

# ─── Standard 7-Step Process Template ──────────────────────────────────────────

STANDARD_PROCESS_STEPS = [
    {"stepNumber": 10, "processKey": "iqc",             "operationName": "IQC (Incoming Quality Control)", "workCenter": "QC-IQC",   "instructions": "Verify incoming raw material quality, certifications, and dimensions.", "requiredSop": "SOP-IQC-01"},
    {"stepNumber": 20, "processKey": "rm_cutting",      "operationName": "RM Cutting",                    "workCenter": "CUT-01",   "instructions": "Cut raw material to specified dimensions per drawing.",               "requiredSop": "SOP-CUT-01"},
    {"stepNumber": 30, "processKey": "machining",       "operationName": "Machining",                     "workCenter": "CNC/VMC",  "instructions": "Machine part per CAM program and drawing specifications.",             "requiredSop": "SOP-MC-01"},
    {"stepNumber": 40, "processKey": "deburring",       "operationName": "Deburring",                     "workCenter": "DEB-01",   "instructions": "Remove all burrs and sharp edges. Clean part.",                       "requiredSop": "SOP-DEB-01"},
    {"stepNumber": 50, "processKey": "laser_marking",   "operationName": "Laser Marking",                 "workCenter": "LASER-01", "instructions": "Laser engrave part number, serial number, and traceability marks.",   "requiredSop": "SOP-LAS-01"},
    {"stepNumber": 60, "processKey": "special_process", "operationName": "Special Process",               "workCenter": "SP-01",    "instructions": "Heat Treatment / Anodising / Surface Treatment as applicable.",       "requiredSop": "SOP-SP-01"},
    {"stepNumber": 70, "processKey": "qc",              "operationName": "QC (Final Quality Control)",    "workCenter": "QC-OQC",   "instructions": "Final quality inspection — verify all critical dimensions and specs.", "requiredSop": "SOP-QC-01"},
]

# ─── Seed Data ─────────────────────────────────────────────────────────────────

_SEED_USERS = [
    {"id": "u-1", "name": "Rajesh Kumar", "email": "admin@asmltd.com", "role": "Admin", "workCenter": "All", "password": _DEFAULT_HASH, "createdAt": "2025-01-10T08:00:00Z"},
    {"id": "u-2", "name": "Priya Sharma", "email": "operator1@asmltd.com", "role": "Operator", "workCenter": "machining", "password": _DEFAULT_HASH, "createdAt": "2025-01-12T09:00:00Z"},
    {"id": "u-3", "name": "Sarah Engineer", "email": "engineer1@asmltd.com", "role": "Shift Engineer", "workCenter": "All", "password": _DEFAULT_HASH, "createdAt": "2025-01-15T10:00:00Z"},
    {"id": "u-4", "name": "Rahul QA", "email": "qc@asmltd.com", "role": "Operator", "workCenter": "iqc", "password": _DEFAULT_HASH, "createdAt": "2025-01-16T10:00:00Z"},
]

def _make_seed_steps():
    """Generate seed steps using the 7 standard processes for demo cards."""
    steps_card1 = []
    for proc in STANDARD_PROCESS_STEPS:
        status = "Pending"
        signed_off_by = None
        signed_off_at = None
        remarks = ""
        if proc["processKey"] == "iqc":
            status = "Completed"
            signed_off_by = "Priya Sharma"
            signed_off_at = "2025-06-01T10:30:00Z"
            remarks = "Material cert verified. All dims within tolerance."
        elif proc["processKey"] == "rm_cutting":
            status = "Completed"
            signed_off_by = "Priya Sharma"
            signed_off_at = "2025-06-02T14:15:00Z"
            remarks = "Cut to 122*60*12 mm."
        elif proc["processKey"] == "machining":
            status = "In Progress"

        steps_card1.append({
            "id": f"s-{_uuid()}", "stepNumber": proc["stepNumber"],
            "processKey": proc["processKey"],
            "operationName": proc["operationName"], "workCenter": proc["workCenter"],
            "instructions": proc["instructions"], "requiredSop": proc["requiredSop"],
            "status": status, "signedOffBy": signed_off_by, "signedOffRole": "Operator" if signed_off_by else None,
            "signedOffAt": signed_off_at, "remarks": remarks,
            "completionQty": None, "iqcResult": None
        })

    steps_card2 = []
    for proc in STANDARD_PROCESS_STEPS:
        status = "Pending"
        extra = {}
        if proc["processKey"] == "iqc":
            status = "Failed"
            extra = {"iqcResult": "FAIL", "deviationReason": "Material cert expired — returned to vendor for replacement.",
                     "deviationFlaggedAt": "2025-06-04T11:30:00Z"}

        steps_card2.append({
            "id": f"s-{_uuid()}", "stepNumber": proc["stepNumber"],
            "processKey": proc["processKey"],
            "operationName": proc["operationName"], "workCenter": proc["workCenter"],
            "instructions": proc["instructions"], "requiredSop": proc["requiredSop"],
            "status": status, "signedOffBy": None, "signedOffRole": None,
            "signedOffAt": None, "remarks": "",
            "completionQty": None, "iqcResult": None,
            **extra
        })

    return steps_card1, steps_card2


_SEED_NOTIFICATIONS = [
    {"id": "n-1", "userId": "u-1", "title": "New Route Card Assigned",
     "message": "RC-2025-1001 has been assigned.", "type": "New Route Card Assigned",
     "read": False, "createdAt": "2025-05-28T08:05:00Z"},
    {"id": "n-2", "userId": "u-2", "title": "New Route Card Assigned",
     "message": "RC-2025-1002 has been assigned.", "type": "New Route Card Assigned",
     "read": False, "createdAt": "2025-06-01T07:35:00Z"},
    {"id": "n-3", "userId": "u-1", "title": "IQC Failed",
     "message": "IQC FAILED on RC-2025-1002: Material cert expired.", "type": "IQC Failed",
     "read": False, "createdAt": "2025-06-04T11:35:00Z"},
]

_SEED_ACTIVITY = [
    {"id": "a-1", "userId": "u-3", "userName": "Sarah Engineer", "userEmail": "engineer1@asmltd.com",
     "action": "route card creation", "details": "Created RC-2025-1001", "timestamp": "2025-05-28T08:00:00Z"},
    {"id": "a-2", "userId": "u-2", "userName": "Priya Sharma", "userEmail": "operator1@asmltd.com",
     "action": "step sign-off", "details": "Signed off IQC on RC-2025-1001", "timestamp": "2025-06-01T10:30:00Z"},
]


class InMemoryDB:
    def __init__(self):
        self.reset()

    def reset(self):
        self.users = copy.deepcopy(_SEED_USERS)

        steps1, steps2 = _make_seed_steps()
        self.cards = [
            {"id": "rc-1001", "cardNumber": "RC-2025-1001", "jobName": "Bracket Assembly - Chassis Mount",
             "partNumber": "ASM-BKT-7742", "partRevision": "B", "batchQuantity": 50,
             "workOrderNumber": "WO-2025-0456", "koNumber": "KO-2025-001",
             "riskLevel": "MEDIUM", "riskScore": 2, "complexity": "MEDIUM", "targetDate": "2025-07-15",
             "notes": "Priority order for UD Croner programme.",
             "createdBy": "Sarah Engineer", "createdAt": "2025-05-28T08:00:00Z",
             "status": "In Progress", "steps": steps1},
            {"id": "rc-1002", "cardNumber": "RC-2025-1002", "jobName": "Bearing Housing - Front Axle",
             "partNumber": "ASM-BRG-3310", "partRevision": "A", "batchQuantity": 25,
             "workOrderNumber": "WO-2025-0461", "koNumber": "KO-2025-001",
             "riskLevel": "HIGH", "riskScore": 3, "complexity": "HIGH", "targetDate": "2025-06-10",
             "notes": "IQC failed — awaiting vendor re-supply.",
             "createdBy": "Sarah Engineer", "createdAt": "2025-06-01T07:30:00Z",
             "status": "On Hold", "steps": steps2},
        ]

        self.notifications = copy.deepcopy(_SEED_NOTIFICATIONS)
        self.activity_logs = copy.deepcopy(_SEED_ACTIVITY)
        self.preferences = {u["id"]: {"emailNotifications": True, "pushNotifications": True,
            "smsNotifications": False, "darkMode": False, "language": "en"} for u in self.users}
        self.otps = {}
        self._card_seq = 1003
        self._notif_seq = 4

    # ─── Auth ──────────────────────────────────────────────────────────────

    def register_user(self, email, name, role, password):
        existing = next((u for u in self.users if u["email"] == email), None)
        if existing:
            return None
        user = {"id": f"u-{len(self.users)+1}", "name": name, "email": email, "role": role, "password": _hash_pw(password), "createdAt": _now()}
        self.users.append(user)
        self.preferences[user["id"]] = {"emailNotifications": True, "pushNotifications": True,
            "smsNotifications": False, "darkMode": False, "language": "en"}
        return user

    def authenticate_user(self, email, password):
        user = next((u for u in self.users if u["email"] == email), None)
        if not user or "password" not in user:
            return None
        if _check_pw(password, user["password"]):
            return user
        return None

    def generate_otp(self, email):
        user = next((u for u in self.users if u["email"] == email), None)
        if not user:
            return None
        otp = str(random.randint(100000, 999999))
        self.otps[email] = otp
        return otp

    def verify_otp(self, email, otp):
        return self.otps.get(email) == otp

    def reset_password(self, email, otp, new_password):
        if not self.verify_otp(email, otp):
            return False
        user = next((u for u in self.users if u["email"] == email), None)
        if user:
            user["password"] = _hash_pw(new_password)
            del self.otps[email]
            return True
        return False

    def get_all_users(self):
        return self.users

    # ─── Route Cards ──────────────────────────────────────────────────────

    def get_all_route_cards(self):
        return [{k: v for k, v in c.items() if k != "steps"} |
                {"stepCount": len(c["steps"]),
                 "completedSteps": sum(1 for s in c["steps"] if s["status"] == "Completed"),
                 "failedSteps": sum(1 for s in c["steps"] if s["status"] == "Failed"),
                 "processProgress": self._get_process_progress(c)}
                for c in self.cards]

    def _get_process_progress(self, card):
        """Return a list of process statuses for the timeline view."""
        progress = []
        for step in card["steps"]:
            progress.append({
                "processKey": step.get("processKey", ""),
                "operationName": step["operationName"],
                "status": step["status"],
                "stepNumber": step["stepNumber"],
            })
        return progress

    def get_route_card_details(self, card_id):
        return next((c for c in self.cards if c["id"] == card_id), None)

    def get_route_cards_by_ko(self, ko_number):
        """Get all route cards grouped under a specific KO number."""
        return [c for c in self.cards if c.get("koNumber", "") == ko_number]

    def create_route_card(self, card_data, steps_data=None):
        """Create a new route card. If no steps provided, auto-generate the 7 standard processes."""
        card_num = f"RC-2025-{self._card_seq:04d}"
        self._card_seq += 1

        if steps_data:
            steps = [{"id": f"s-{_uuid()}", "stepNumber": s.get("stepNumber", (i+1)*10),
                      "processKey": s.get("processKey", ""),
                      "operationName": s["operationName"], "workCenter": s.get("workCenter", "WIP"),
                      "instructions": s["instructions"], "requiredSop": s.get("requiredSop", "SOP-GEN-01"),
                      "status": "Pending", "signedOffBy": None, "signedOffRole": None,
                      "signedOffAt": None, "remarks": "", "completionQty": None, "iqcResult": None}
                     for i, s in enumerate(steps_data)]
        else:
            # Auto-generate 7 standard process steps
            steps = []
            for proc in STANDARD_PROCESS_STEPS:
                steps.append({
                    "id": f"s-{_uuid()}", "stepNumber": proc["stepNumber"],
                    "processKey": proc["processKey"],
                    "operationName": proc["operationName"], "workCenter": proc["workCenter"],
                    "instructions": proc["instructions"], "requiredSop": proc["requiredSop"],
                    "status": "Pending", "signedOffBy": None, "signedOffRole": None,
                    "signedOffAt": None, "remarks": "", "completionQty": None, "iqcResult": None
                })

        card = {"id": f"rc-{_uuid()}", "cardNumber": card_num, **card_data,
                "createdAt": _now(), "status": "Pending", "steps": steps}
        self.cards.append(card)
        return card

    # ─── Step Actions ──────────────────────────────────────────────────────

    def _find(self, card_id, step_id):
        card = next((c for c in self.cards if c["id"] == card_id), None)
        if not card: return None, None
        step = next((s for s in card["steps"] if s["id"] == step_id), None)
        return card, step

    def _recalc(self, card):
        sts = [s["status"] for s in card["steps"]]
        if all(s in ("Completed", "N/A") for s in sts):
            card["status"] = "Completed"
        elif any(s == "Failed" for s in sts):
            card["status"] = "On Hold"
        elif any(s == "Deviated" for s in sts):
            card["status"] = "On Hold"
        elif any(s in ("In Progress", "Completed") for s in sts):
            card["status"] = "In Progress"
        else:
            card["status"] = "Pending"

    def update_step_sign_off(self, card_id, step_id, name, role, remarks=None, completion_qty=None):
        card, step = self._find(card_id, step_id)
        if not card or not step: return None

        # For IQC step, mark as passed
        if step.get("processKey") == "iqc":
            step["iqcResult"] = "PASS"

        step.update({"status": "Completed", "signedOffBy": name, "signedOffRole": role,
                     "signedOffAt": _now(), "remarks": remarks or ""})
        if completion_qty is not None:
            step["completionQty"] = completion_qty

        self._recalc(card)
        return card

    def update_step_progress(self, card_id, step_id):
        card, step = self._find(card_id, step_id)
        if not card or not step: return None
        if step["status"] in ("Pending", "Failed"):
            step["status"] = "In Progress"
            # If IQC was previously failed and now re-started, clear the failure
            if step.get("processKey") == "iqc" and step.get("iqcResult") == "FAIL":
                step["iqcResult"] = None
                step.pop("deviationReason", None)
                step.pop("deviationFlaggedAt", None)
        self._recalc(card)
        return card

    def update_step_deviation(self, card_id, step_id, reason, remarks=None):
        card, step = self._find(card_id, step_id)
        if not card or not step: return None
        step.update({"status": "Deviated", "deviationReason": reason,
                     "deviationFlaggedAt": _now(), "remarks": remarks or ""})
        self._recalc(card)
        return card

    def update_iqc_fail(self, card_id, step_id, reason, remarks=None):
        """Mark IQC step as Failed — triggers reject/return to vendor."""
        card, step = self._find(card_id, step_id)
        if not card or not step: return None
        if step.get("processKey") != "iqc":
            return None  # Can only fail IQC step
        step.update({
            "status": "Failed",
            "iqcResult": "FAIL",
            "deviationReason": reason,
            "deviationFlaggedAt": _now(),
            "remarks": remarks or "",
        })
        self._recalc(card)
        return card

    def update_iqc_reinspect(self, card_id, step_id, remarks=None):
        """Reset IQC step for re-inspection after vendor return."""
        card, step = self._find(card_id, step_id)
        if not card or not step: return None
        if step.get("processKey") != "iqc":
            return None
        step.update({
            "status": "In Progress",
            "iqcResult": None,
            "remarks": f"Re-inspection after vendor return. {remarks or ''}".strip(),
        })
        step.pop("deviationReason", None)
        step.pop("deviationFlaggedAt", None)
        self._recalc(card)
        return card

    def resolve_deviation(self, card_id, step_id, remarks, engineer_name):
        card, step = self._find(card_id, step_id)
        if not card or not step: return None
        step["status"] = "Pending"
        step["remarks"] = f"Resolved by {engineer_name}: {remarks}"
        step.pop("deviationReason", None)
        step.pop("deviationFlaggedAt", None)
        self._recalc(card)
        return card

    # ─── Notifications ─────────────────────────────────────────────────────

    def get_notifications(self, user_id):
        return [n for n in self.notifications if n["userId"] == user_id]

    def create_notification(self, user_id, title, message, notif_type):
        prefs = self.preferences.get(user_id, {})
        if not prefs.get("pushNotifications", True): return None
        n = {"id": f"n-{self._notif_seq}", "userId": user_id, "title": title, "message": message,
             "type": notif_type, "read": False, "createdAt": _now()}
        self._notif_seq += 1
        self.notifications.append(n)
        return n

    def mark_notification_read(self, notif_id):
        n = next((n for n in self.notifications if n["id"] == notif_id), None)
        if n: n["read"] = True; return True
        return False

    def mark_all_notifications_read(self, user_id):
        for n in self.notifications:
            if n["userId"] == user_id: n["read"] = True
        return True

    # ─── Preferences ───────────────────────────────────────────────────────

    def get_user_preferences(self, user_id):
        return self.preferences.get(user_id, {"emailNotifications": True, "pushNotifications": True,
            "smsNotifications": False, "darkMode": False, "language": "en"})

    def update_user_preferences(self, user_id, updates):
        prefs = self.preferences.setdefault(user_id, {"emailNotifications": True, "pushNotifications": True,
            "smsNotifications": False, "darkMode": False, "language": "en"})
        prefs.update(updates)
        return prefs

    # ─── Activity Logs ─────────────────────────────────────────────────────

    def log_activity(self, user_id, user_name, user_email, action, details):
        self.activity_logs.append({"id": f"a-{_uuid()}", "userId": user_id, "userName": user_name,
            "userEmail": user_email, "action": action, "details": details, "timestamp": _now()})

    def get_activity_logs(self):
        return sorted(self.activity_logs, key=lambda a: a["timestamp"], reverse=True)

db = InMemoryDB()
