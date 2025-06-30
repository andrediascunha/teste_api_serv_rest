FROM python:3.11-slim

COPY requirements.txt /tmp/

RUN pip install --upgrade pip
RUN pip install -r /tmp/requirements.txt

WORKDIR /tests
COPY . /tests

CMD ["robot", "."]