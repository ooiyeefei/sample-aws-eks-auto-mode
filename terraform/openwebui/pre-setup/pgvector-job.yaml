apiVersion: batch/v1
kind: Job
metadata:
  name: pgvector-setup
  namespace: ${namespace}
spec:
  # This makes the job fail faster if it can't complete.
  backoffLimit: 2 
  template:
    spec:
      # We need a service account to give permissions, but for this method,
      # we are getting secrets directly, so 'default' is fine.
      containers:
      - name: pgvector-setup
        image: postgres:15
        # THE FIX: Mount all connection details from the secret as environment variables.
        env:
        - name: PGHOST
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: host
        - name: PGPORT
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: port
        - name: PGUSER
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: username
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: password
        - name: PGDATABASE
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: dbname
        # 'psql' will automatically use the PG* environment variables to connect.
        command: ["psql", "-c", "CREATE EXTENSION IF NOT EXISTS vector;"]
      restartPolicy: OnFailure