#!/usr/bin/env sh
# Dry Run installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bhanotblocker/dryrun/main/install.sh | sh

set -e

DRYRUN_IMAGE="varundagger/dryrun:latest"
INSTALL_DIR="/usr/local/bin"
WRAPPER="$INSTALL_DIR/dryrun"

echo ""
echo "  Installing Dry Run — LocalStack for Databricks"
echo ""

# Check Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "  Error: Docker is not installed."
  echo "  Install Docker Desktop from https://www.docker.com/products/docker-desktop"
  exit 1
fi

# Pull the latest image
echo "  Pulling dryrun image..."
docker pull "$DRYRUN_IMAGE"

# Write the wrapper script
cat > /tmp/dryrun_wrapper << 'WRAPPER_EOF'
#!/usr/bin/env sh
# Dry Run wrapper — runs the dryrun CLI inside Docker, mounting the current
# directory as the user's Databricks project. Users never see our source
# code; they just see their own files + whatever Dry Run writes to .dryrun/.

DRYRUN_IMAGE="varundagger/dryrun:latest"
WORKSPACE="$(pwd)"
SUBCOMMAND="${1:-}"

# `dryrun up` needs special handling: bind to 0.0.0.0 (container loopback
# isn't reachable from the host), stay in the foreground (so the container
# doesn't exit), publish the dashboard port, and allocate a TTY so Ctrl-C
# cleanly stops the server.
if [ "$SUBCOMMAND" = "up" ]; then
  shift
  exec docker run --rm -it \
    -p 8000:8000 \
    -v "$WORKSPACE:/workspace" \
    -e DRYRUN_ROOT=/workspace \
    "$DRYRUN_IMAGE" up --host 0.0.0.0 --port 8000 --foreground "$@"
fi

# Everything else (run, hydrate, sql, export, diff, savings, init, …) is a
# one-shot command. No port publish, no TTY, container exits when done.
exec docker run --rm \
  -v "$WORKSPACE:/workspace" \
  -e DRYRUN_ROOT=/workspace \
  "$DRYRUN_IMAGE" "$@"
WRAPPER_EOF

chmod +x /tmp/dryrun_wrapper

# Install (needs sudo if /usr/local/bin requires it)
if [ -w "$INSTALL_DIR" ]; then
  mv /tmp/dryrun_wrapper "$WRAPPER"
else
  echo "  (needs sudo to write to $INSTALL_DIR)"
  sudo mv /tmp/dryrun_wrapper "$WRAPPER"
fi

echo ""
echo "  Done! Dry Run is installed."
echo ""
echo "  Usage:"
echo "    cd your-databricks-project"
echo "    dryrun hydrate"
echo "    dryrun run <job-name>"
echo "    dryrun up            # dashboard at http://localhost:8000"
echo ""
