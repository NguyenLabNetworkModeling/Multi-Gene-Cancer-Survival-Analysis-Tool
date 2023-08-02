# syntax=docker/dockerfile:1
FROM python:3.8
WORKDIR cansat
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
EXPOSE 5000
COPY . .
CMD ["python3", "app.py"]
