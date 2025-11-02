#!/bin/bash
set -e

cd "$(dirname "$0")"
export PATH="$HOME/.dotnet:$PATH"
export LD_LIBRARY_PATH=../shared/build:$LD_LIBRARY_PATH

echo "Building C# benchmark..."
dotnet build benchmark.csproj -c Release

echo ""
echo "Running C# benchmark..."
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo ""

dotnet run --project benchmark.csproj -c Release

