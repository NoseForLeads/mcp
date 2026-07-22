# Stdio shim for the remote Nose for Leads MCP server.
# The server itself is remote-hosted (https://api.noseforleads.com/mcp, streamable
# HTTP); this image runs the standard mcp-remote proxy so stdio-only MCP clients
# (and Glama's release build/security scan) can talk to it. The endpoint serves
# initialize/tools-list without auth; tool calls require OAuth or an API key.
FROM node:22-slim
RUN npm install -g mcp-remote
CMD ["mcp-remote", "https://api.noseforleads.com/mcp"]
