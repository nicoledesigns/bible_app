"""
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")  # Set this env var

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For testing, allow all origins. Lock down for production!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/ask")
async def ask(request: Request):
    data = await request.json()
    question = data.get("question", "")

    prompt = f"""
    You are a Christian AI assistant. Please answer the following question clearly from a biblical perspective:

    Question: {question}
    Answer:
    """

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=500,
            temperature=0.7,
        )
        answer = response.choices[0].message.content.strip()
        return {"response": answer}
    except Exception as e:
        return {"response": f"Error: {str(e)}"}
"""