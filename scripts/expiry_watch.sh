#!/bin/bash
# expiry_watch.sh - Monitor password and SSL certificate expiry

check_cert_expiry() {
  domain=$1
  end_date=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null     | openssl x509 -noout -enddate | cut -d= -f2)
  end_date_seconds=$(date -d "$end_date" +%s)
  now_seconds=$(date +%s)
  days_left=$(( (end_date_seconds - now_seconds) / 86400 ))
  echo "[CERT] $domain expires in $days_left days"
}

check_user_expiry() {
  user=$1
  expiry=$(chage -l $user | grep 'Account expires' | cut -d: -f2)
  echo "[USER] $user expiry: $expiry"
}

# Example usage
check_cert_expiry google.com
check_user_expiry root
