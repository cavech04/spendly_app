from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import User, Expense
import schemas
import auth

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.get("/", response_model=List[schemas.ExpenseOut])
def list_expenses(
    db: Session = Depends(get_db),
    current_user: User = Depends(auth.get_current_user),
):
    return (
        db.query(Expense)
        .filter(Expense.owner_id == current_user.id)
        .order_by(Expense.date.desc())
        .all()
    )


@router.post("/", response_model=schemas.ExpenseOut, status_code=status.HTTP_201_CREATED)
def create_expense(
    expense: schemas.ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(auth.get_current_user),
):
    new_expense = Expense(
        **expense.model_dump(),
        owner_id=current_user.id,
    )
    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)
    return new_expense


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    expense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(auth.get_current_user),
):
    expense = (
        db.query(Expense)
        .filter(Expense.id == expense_id, Expense.owner_id == current_user.id)
        .first()
    )
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")

    db.delete(expense)
    db.commit()
    return None