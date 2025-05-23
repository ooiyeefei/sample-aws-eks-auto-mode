apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config
  namespace: litellm
data:
  config.yaml: |
    model_list:
      - model_name: vllm-model
        litellm_params:
          model: vllm/model
          api_base: "${vllm_service_url}"
          timeout: 300

    litellm_settings:
      success_callback: ["redis"]
      cache: true
      cache_params:
        type: "redis"
        host: "${redis_host}"
        port: ${redis_port}
        password: "${redis_password}"
        ssl: true
        ssl_certfile: null
        ssl_keyfile: null
        ssl_ca_certs: null

    general_settings:
      master_key: "${litellm_master_key}"
      database_url: "${database_url}"
      disable_spend_logs: false
      disable_usage_tracking: false
      disable_telemetry: true
      routing_strategy: "simple-shuffle"
      num_retries: 3
      allowed_origins: ["*"]

    environment_variables:
      LITELLM_SALT_KEY: "${litellm_salt_key}"
