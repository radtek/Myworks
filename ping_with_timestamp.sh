# ping with timestamp in bash
ping www.google.fr | while read pong; do echo "$(date): $pong"; done
