from fastapi import FastAPI

app = FastAPI(title="hello")


@app.get("/")
def root():
    return {"message": "hello from docker compose"}
