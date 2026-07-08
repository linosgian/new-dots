#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
  echo ""
  echo "Stopping..."
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null
  wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

echo "Building backend..."
cd "$ROOT/backend"
go build -o cintaye-backend .

echo "Starting backend on :8080..."
./cintaye-backend &
BACKEND_PID=$!

echo "Starting frontend on :5173..."
cd "$ROOT/frontend"
nix-shell -p nodejs_22 --run "npm run dev" &
FRONTEND_PID=$!

echo ""
echo "  Backend:  http://localhost:8080"
echo "  Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop."

wait "$BACKEND_PID" "$FRONTEND_PID"
