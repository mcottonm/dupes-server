# Тестовое задание https://gist.github.com/zemlya25/585ab3fb3b0704880f920728c7598beb

Присутсвует поддержка актуальности. Обновление происходит раз в 10 сек.

Проверялось на Ubuntu 20.04.3 LTS
Требует наличия docker

# Установка:

1. ./deploy.sh

# Тесты:

## ./test/simple_test_sh

Проверяет логику на малых данных

## ./test/hard_test_sh

Проверяет работоспособность сервиса с таблицей в 1м строк и более 20к уникальных user_id

# REST API:
GET $SERVER_HOST:$SERVER_PORT/{id1:[0-9]+}/{id2:[0-9]+}

По умолчанию:
SERVER_HOST="0.0.0.0"
SERVER_PORT="9696"