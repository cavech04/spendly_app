from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine, Base
from routers import auth_router, expenses_router

# Create database tables (for development; in production use proper migrations)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Spendly API")

# CORS: allow requests from the Flutter app (mobile/web/emulator)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for development only; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(expenses_router.router)


@app.get("/")
def root():
    return {"message": "Spendly API is running"}