# Parcelo tracker: the Dockerfile the team has been shipping with.
#
# It works. `docker compose up` builds it and the API answers on port 8000.
#
# It is also the image a tired developer writes on a Friday night, and it has
# at least eight problems that matter in production: size, build speed,
# security and how the process behaves when the platform asks it to stop.
#
# Fixing it is Week 1, task 1.6. Do not look for the list of problems here.
# Find them yourself with `docker history`, `docker run`, hadolint, a scanner
# and the guidance in assignment/execution-guidelines.md, then explain each fix in
# your own words in docs/pipeline.md. Keep this original in git history so you
# can show a before and after (image size, build time, scan findings).

FROM python:3.13

WORKDIR /app

COPY . .

RUN pip install -r requirements-dev.txt

EXPOSE 8000

CMD uvicorn app.main:app --host 0.0.0.0 --port 8000
