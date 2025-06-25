apiVersion: batch/v1
kind: Job
metadata:
  name: pgvector-setup
  namespace: ${namespace}
spec:
  template:
    spec:
      containers:
      - name: pgvector-setup
        image: postgres:15
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: openwebui-db-credentials
              key: password
        command: ["/bin/sh", "-c"]
        args:
          - |
            psql -h $(kubectl get secret openwebui-db-credentials -n ${namespace} -o jsonpath='{.data.host}' | base64 -d) \
                 -U $(kubectl get secret openwebui-db-credentials -n ${namespace} -o jsonpath='{.data.username}' | base64 -d) \
                 -d $(kubectl get secret openwebui-db-credentials -n ${namespace} -o jsonpath='{.data.dbname}' | base64 -d) \
                 -c 'CREATE EXTENSION IF NOT EXISTS vector;';
      restartPolicy: OnFailure 