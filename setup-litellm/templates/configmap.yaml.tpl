apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config
  namespace: litellm
data:
  config.yaml: |
    model_list:
      - model_name: deepseek
        litellm_params:
          model: openai/deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
          api_base: "${vllm_service_url}"
          api_key: "dummy"
          num_retries: 3

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
      # master_key and database_url will be set via environment variables
      disable_spend_logs: false
      disable_usage_tracking: false
      disable_telemetry: true
      routing_strategy: "simple-shuffle"
      num_retries: 3
      allowed_origins: ["*"]
