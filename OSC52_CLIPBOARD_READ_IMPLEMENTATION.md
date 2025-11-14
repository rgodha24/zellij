# OSC52 Clipboard Read Implementation

## Overview

This implementation adds support for reading from the clipboard using OSC52 in Zellij. This allows applications running inside Zellij (like Neovim) to read clipboard content via OSC52 queries, which is particularly useful when accessing Zellij over SSH where the clipboard is managed by the terminal emulator (e.g., Ghostty).

## Implementation Summary

### Flow

1. **Pane detects clipboard read request**: When a pane sends `ESC]52;c;?ESC\` (OSC52 read query)
2. **Tab forwards to Screen**: Tab detects this and sends `ScreenInstruction::RequestClipboardFromClient`
3. **Screen requests from first client**: Screen sends `ServerToClientMsg::RequestClipboardRead` to the first connected client
4. **Client queries terminal**: Client sends `ESC]52;c;?ESC\` to the terminal emulator (Ghostty, etc.)
5. **Client parses response**: Client receives `ESC]52;c;<base64>ESC\` from terminal and decodes it
6. **Client responds to server**: Client sends `ClientToServerMsg::ClipboardReadResponse` back
7. **Screen writes to pane**: Screen formats the clipboard content as OSC52 response and writes it to the active pane

### Design Decisions

- **Always use first connected client**: Simplified approach for personal fork - clipboard reads always query the first connected client
- **No complex request tracking**: Uses request_id=0 for all requests (can be enhanced later if needed)
- **Active pane receives response**: The response is written to the currently active pane
- **No timeout mechanism initially**: Can be added if needed, but terminals typically respond quickly

### Files Modified

#### Protocol Layer
- `zellij-utils/src/client_server_contract/client_to_server.proto` - Added `ClipboardReadResponseMsg`
- `zellij-utils/src/client_server_contract/server_to_client.proto` - Added `RequestClipboardReadMsg`
- `zellij-utils/assets/prost_ipc/client_server_contract.rs` - Auto-generated protobuf Rust code
- `zellij-utils/src/ipc.rs` - Added Rust enum variants for new messages
- `zellij-utils/src/ipc/protobuf_conversion.rs` - Added conversions between Rust and protobuf
- `zellij-utils/src/errors.rs` - Added context types

#### Server Side
- `zellij-server/src/panes/grid.rs` - Detects OSC52 read requests (`?` parameter)
- `zellij-server/src/panes/terminal_pane.rs` - Added `drain_clipboard_read_request()` method
- `zellij-server/src/tab/mod.rs` - Forwards clipboard requests to Screen
- `zellij-server/src/screen.rs` - Added `ScreenInstruction` variants and handling, sends requests to clients
- `zellij-server/src/route.rs` - Routes clipboard responses from clients to Screen

#### Client Side
- `zellij-client/src/lib.rs` - Added `ClientInstruction::RequestClipboardRead`, sends OSC52 to terminal
- `zellij-client/src/stdin_ansi_parser.rs` - Parses OSC52 responses from terminal
- `zellij-client/src/input_handler.rs` - Handles parsed responses and sends to server

## Testing

To test the implementation:

1. SSH into your machine running Zellij
2. Ensure your local terminal (e.g., Ghostty) supports OSC52
3. Copy something to your local clipboard
4. In a pane, run: `printf "\e]52;c;?\e\\"` - this should print the clipboard content
5. In Neovim with OSC52 clipboard support configured, use `"+p` to paste from clipboard

## Future Enhancements

- **Proper request tracking**: Track multiple concurrent requests with unique IDs
- **Timeout mechanism**: Add 2-second timeout for unresponsive terminals  
- **Per-client selection**: Allow choosing which client to query (currently always first)
- **Error handling**: Better handling of decode failures and malformed responses

## Known Limitations

- Always queries the first connected client (by design for personal fork)
- No timeout - if terminal doesn't respond, the request hangs (terminals typically respond quickly)
- Uses environment variable for request_id tracking (simplified approach)
- Response always goes to active pane (not the requesting pane if it changed)

## Compatibility

This implementation follows Zellij's existing patterns:
- Uses the same client-server message architecture as `QueryTerminalSize`
- Mirrors the clipboard write flow (but in reverse)
- Minimal changes to existing codebase
- No breaking changes to existing functionality
