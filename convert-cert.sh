#!/bin/bash

# Путь к исходному файлу и целевой директории
ACME_JSON="./letsencrypt/acme.json"
CONF_DIR="./adguard/confdir"
DOMAIN="kb5snr05.mynotation.ru"

# Проверка существования исходного файла
if [[ ! -f "$ACME_JSON" ]]; then
  echo "Файл $ACME_JSON не найден!"
  exit 1
fi

# Проверка существования целевой директории
if [[ ! -d "$CONF_DIR" ]]; then
  echo "Директория $CONF_DIR не найдена, создаем..."
  mkdir -p "$CONF_DIR"
fi

# Извлечение сертификата и ключа для указанного домена
CERTIFICATE=$(jq -r --arg DOMAIN "$DOMAIN" '.myresolver.Certificates[] | select(.domain.main == $DOMAIN) | .certificate' "$ACME_JSON")
PRIVATE_KEY=$(jq -r --arg DOMAIN "$DOMAIN" '.myresolver.Certificates[] | select(.domain.main == $DOMAIN) | .key' "$ACME_JSON")

# Проверка на успешность извлечения данных
if [[ -z "$CERTIFICATE" || -z "$PRIVATE_KEY" ]]; then
  echo "Не удалось извлечь сертификат или ключ для домена $DOMAIN из $ACME_JSON!"
  exit 1
fi

# Удаление старых файлов перед записью новых
rm -f "$CONF_DIR/adguard.crt" "$CONF_DIR/adguard.key"

# Декодируем base64 сертификат и ключ и записываем их в файлы
echo "$CERTIFICATE" | base64 --decode > "$CONF_DIR/adguard.crt"
if [[ $? -ne 0 ]]; then
  echo "Ошибка при декодировании сертификата!"
  exit 1
fi

echo "$PRIVATE_KEY" | base64 --decode > "$CONF_DIR/adguard.key"
if [[ $? -ne 0 ]]; then
  echo "Ошибка при декодировании ключа!"
  exit 1
fi

# Установка правильных прав на файлы
chmod 600 "$CONF_DIR/adguard.crt" "$CONF_DIR/adguard.key"

echo "Сертификат и ключ для домена $DOMAIN успешно сконвертированы и сохранены в $CONF_DIR"
