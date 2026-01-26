contact_name="Rong Zhou"

grep "contact_name=\"$contact_name\"" sms-20260114073830.xml \
  | grep 'body="' \
  | grep -v 'body=""' \
  | awk '{
      match($0, /readable_date="([^"]*)"/, d);
      match($0, /address="([^"]*)"/, a);
      match($0, /body="([^"]*)"/, b);
      printf("[%s] %s : %s\n", d[1], a[1], b[1]);
  }' \
  > "${contact_name}-konversacia-sekurkopio.txt"
