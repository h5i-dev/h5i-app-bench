FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends git socat ca-certificates ripgrep less \
 && rm -rf /var/lib/apt/lists/* && git config --system safe.directory '*'
ENV PATH=/opt/lean/bin:/opt/codex:$PATH HOME=/work/home
WORKDIR /work/task
