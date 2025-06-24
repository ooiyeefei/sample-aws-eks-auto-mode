db:
  host: "{{ .Values.db.host | default (lookup "v1" "Secret" .Release.Namespace "openwebui-db-credentials").data.host | b64dec }}"
  port: "{{ .Values.db.port | default (lookup "v1" "Secret" .Release.Namespace "openwebui-db-credentials").data.port | b64dec }}"
  user: "{{ .Values.db.user | default (lookup "v1" "Secret" .Release.Namespace "openwebui-db-credentials").data.username | b64dec }}"
  password: "{{ .Values.db.password | default (lookup "v1" "Secret" .Release.Namespace "openwebui-db-credentials").data.password | b64dec }}"
  name: "{{ .Values.db.name | default (lookup "v1" "Secret" .Release.Namespace "openwebui-db-credentials").data.dbname | b64dec }}" 