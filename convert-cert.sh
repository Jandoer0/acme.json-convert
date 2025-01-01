#!/bin/bash

# Путь к исходному файлу и целевой директории
ACME_JSON="/home/suave/docker/traefik/letsencrypt/acme.json"
CONF_DIR="./adguard/confdir"
DOMAIN="exemple.com"

# Параметры для логирования
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/script.log"
LOG_RETENTION_DAYS=1  # Количество дней для хранения логов
CURRENT_DATE=$(date "+%Y-%m-%d")

# Создание директории для логов, если она не существует
mkdir -p "$LOG_DIR"

# Функция для записи в лог
log_message() {
    local MESSAGE=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $MESSAGE" >> "$LOG_FILE"
}

# Ротация логов (удаление логов старше указанного количества дней)
rotate_logs() {
    find "$LOG_DIR" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS -exec rm -f {} \;
}

# Ротация логов перед началом работы скрипта
rotate_logs

# Запись в лог: начало выполнения скрипта
log_message "Запуск скрипта для домена $DOMAIN"

# Проверка существования исходного файла
if [[ ! -f "$ACME_JSON" ]]; then
  log_message "Файл $ACME_JSON не найден!"
  echo "Файл $ACME_JSON не найден!"
  exit 1
fi
log_message "Файл $ACME_JSON найден."

# Проверка существования целевой директории
if [[ ! -d "$CONF_DIR" ]]; then
  log_message "Директория $CONF_DIR не найдена, создаем..."
  echo "Директория $CONF_DIR не найдена, создаем..."
  mkdir -p "$CONF_DIR"
  log_message "Директория $CONF_DIR создана."
fi

# Извлечение сертификата и ключа для указанного домена
CERTIFICATE=$(jq -r --arg DOMAIN "$DOMAIN" '.myresolver.Certificates[] | select(.domain.main == $DOMAIN) | .certificate' "$ACME_JSON")
PRIVATE_KEY=$(jq -r --arg DOMAIN "$DOMAIN" '.myresolver.Certificates[] | select(.domain.main == $DOMAIN) | .key' "$ACME_JSON")

# Проверка на успешность извлечения данных
if [[ -z "$CERTIFICATE" || -z "$PRIVATE_KEY" ]]; then
  log_message "Не удалось извлечь сертификат или ключ для домена $DOMAIN из $ACME_JSON!"
  echo "Не удалось извлечь сертификат или ключ для домена $DOMAIN из $ACME_JSON!"
  exit 1
fi
log_message "Сертификат и ключ для домена $DOMAIN извлечены."

# Удаление старых файлов перед записью новых
rm -f "$CONF_DIR/adguard.crt" "$CONF_DIR/adguard.key"
log_message "Удалены старые файлы: adguard.crt и adguard.key."

# Декодируем base64 сертификат и ключ и записываем их в файлы
echo "$CERTIFICATE" | base64 --decode > "$CONF_DIR/adguard.crt"
if [[ $? -ne 0 ]]; then
  log_message "Ошибка при декодировании сертификата!"
  echo "Ошибка при декодировании сертификата!"
  exit 1
fi
log_message "Сертификат успешно декодирован и сохранен в $CONF_DIR/adguard.crt."

echo "$PRIVATE_KEY" | base64 --decode > "$CONF_DIR/adguard.key"
if [[ $? -ne 0 ]]; then
  log_message "Ошибка при декодировании ключа!"
  echo "Ошибка при декодировании ключа!"
  exit 1
fi
log_message "Ключ успешно декодирован и сохранен в $CONF_DIR/adguard.key."

# Установка правильных прав на файлы
chmod 600 "$CONF_DIR/adguard.crt" "$CONF_DIR/adguard.key"
log_message "Установлены права доступа 600 для файлов сертификата и ключа."

# Запись в лог: успешное завершение
log_message "Скрипт успешно завершен. Сертификат и ключ для домена $DOMAIN сохранены в $CONF_DIR."

# Завершающее сообщение
echo "Сертификат и ключ для домена $DOMAIN успешно сконвертированы и сохранены в $CONF_DIR."
