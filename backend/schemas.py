from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime
from typing import Optional


# ---------- User schemas ----------

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    name: str
    email: EmailStr

    model_config = ConfigDict(from_attributes=True)


# ---------- Token schema ----------

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ---------- Expense schemas ----------

class ExpenseCreate(BaseModel):
    title: str
    amount: float
    category: str
    date: datetime
    note: Optional[str] = None


class ExpenseOut(BaseModel):
    id: int
    title: str
    amount: float
    category: str
    date: datetime
    note: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)