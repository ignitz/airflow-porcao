# Airflow porcão

Um deploy simples do Airflow em uma EC2 e bucket que sincroniza as dags feito em uma hora. Não use isso em produção de jeito nenhum pela mor de Deus.

Esse código serve como demonstração do terraform com Airflow se quiser testar algo Just-in-time.

## F\*\*\*-se quero rodar isso aqui

Obviamente precisa de terraform e credenciais da AWS.

Edit o arquivo `init.sh` mudando as configurações do backend.

```shell
BACKEND_S3_BUCKET=yuriniitsuma # Bucket para armezenar o estado do terraform
CI_PROJECT_PATH=boizao # um prefixo para diferenciar. Essa variável é o path do projeto do gitlab
...
```

Rode o comando `bash init.sh` e depois `terraform apply -auto-approve` e vá fazer um café.

Acesse o airflow via ip externo da instância ec2 criada:

- `http://IP_DO_AIRFLOW:8080`
- user: `airflow` password: `airflow`
- Copie as dags para o bucket criado na pasta `s3://<BUCKET>/dags` que de minuto em minuto será sincronizado no airflow.

That's all folks.
