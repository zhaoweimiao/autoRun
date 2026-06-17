FROM python:3.12-slim

WORKDIR /workspace/playbook
COPY . .

RUN apt update && apt install -y git && apt clean && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir ./benchmark
RUN ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

ENTRYPOINT ["python", "playbook.py"]
