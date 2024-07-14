# For more information, please refer to https://aka.ms/vscode-docker-python

FROM node as nodeMachine
# FROM node:slim
WORKDIR /app
COPY . /app
# Install npm dependencies (if any)
RUN npm install

# Build the c files. 
RUN node_modules/tree-sitter-cli/tree-sitter generate

# FROM gcc
FROM gcc as gccMachine
WORKDIR /app
COPY . /app
COPY --from=nodeMachine /app/src /app/src

# Build the SO file after the c files are generated. 
RUN gcc -o medfordparser.so -shared ./src/parser.c -I ./src -fPIC


FROM python:3.8-alpine
WORKDIR /app
COPY . /app
COPY --from=gccMachine /app/medfordparser.so /app
# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Install pip requirements
COPY requirements.txt .
RUN python -m pip install -r requirements.txt


# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["python", "python_sample.py"]
