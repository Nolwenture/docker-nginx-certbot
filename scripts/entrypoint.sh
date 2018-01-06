#!/bin/sh

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

# Source in util.sh so we can have our nice tools
. $(cd $(dirname $0); pwd)/util.sh

# Immediately run auto_enable_configs so that nginx is in a runnable state
auto_enable_configs

# Start up nginx
nginx -g "daemon off;" &

# Next, run certbot to request all the ssl certs we can find
/scripts/run_certbot.sh

# Lastly, run startup scripts
for f in /scripts/startup/*.sh; do
    if [[ -x "$f" ]]; then
        echo "Running startup script $f"
        $f
    fi
done
echo "Done with startup"

# Run `cron -f &` so that it's a background job owned by bash and then `wait`.
# This allows SIGINT (e.g. CTRL-C) to kill cron gracefully, due to our `trap`.
cron -f &
wait "$(cat /var/run/nginx.pid)"
