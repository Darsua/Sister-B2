FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    gnucobol \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY app.py index.html main.cob accounts.txt requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

RUN cobc -x main.cob -o main

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
