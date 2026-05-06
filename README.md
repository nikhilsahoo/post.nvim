> [!NOTE]
> This project is currently under development and I am working towards making it available for public use as soon as possible.

# post.nvim
`post.nvim` is a powerful plugin for Neovim aimed at streamlining the process of testing REST APIs directly within the editor. It provides a seamless interface for sending HTTP requests, inspecting responses, and managing test suites, all without leaving your coding environment.

## Key Features:
- Interactive Request Builder: Construct HTTP requests effortlessly using an interactive interface within Neovim. With intuitive autocomplete and syntax highlighting, crafting requests becomes a breeze.
- Multiple Request Methods: Support for various HTTP methods including GET, POST, PUT, DELETE, PATCH, and more. Quickly switch between methods to simulate different API interactions.
- Flexible Authentication: Easily authenticate your requests with support for various authentication methods such as Basic Auth, OAuth, API keys, and bearer tokens. Manage and save authentication credentials securely.
- Dynamic Variables: Seamlessly inject dynamic variables into your requests for parameterization. Variables can be generated from responses, user input, or environment variables, allowing for dynamic and flexible testing scenarios.
- Response Inspection: View HTTP responses directly within Neovim, complete with syntax-highlighted JSON or XML formatting for easy readability. Navigate through response headers and body effortlessly to debug and analyze API responses.
- Test Suites and Assertions: Organize your API tests into test suites and define assertions to verify expected responses. `post.nvim` supports a wide range of assertion methods, allowing for comprehensive testing of API endpoints.
- Environment Management: Define multiple environments (e.g., development, staging, production) and switch between them seamlessly. Environment variables can be scoped globally or within specific test suites for fine-grained control.
- Extensibility: `post.nvim` is highly extensible, allowing users to customize and extend its functionality through Lua scripting. Integrate with other plugins or extend existing features to suit your workflow.

## Installation

**lazy.nvim:**
```lua
{
  "nikhilsahoo/post.nvim",
  config = function()
    require("post-nvim").setup({
      -- optional config
      curl = {
        proxy = nil,
        insecure = false,
        connect_timeout = 30,
        max_time = 60,
      },
      ui = {
        response_split = "vertical", -- "horizontal" or "vertical"
        response_size = 60,
      },
    })
  end,
}
```

## Usage

### Request Format (`.http` files)

```http
GET https://api.example.com/users
Authorization: Bearer {{token}}
Content-Type: application/json

{"query": "active"}
```

Or as JSON:

```json
{
  "method": "POST",
  "url": "{{base_url}}/users",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"name\": \"John\"}",
  "auth": {
    "type": "bearer",
    "token": "{{token}}"
  },
  "tests": [
    { "type": "status", "value": 201 },
    { "type": "jsonpath", "key": "id", "operator": "neq", "value": null }
  ]
}
```

### Commands

| Command | Description |
|---|---|
| `:PostRun` | Run HTTP request from current buffer |
| `:PostRunVisual` | Run HTTP request from visual selection |
| `:PostEnv [name]` | Switch to environment, or list environments |
| `:PostSessions` | List stored session history |
| `:PostSessionDelete <name>` | Delete a specific session |
| `:PostSessionGC` | Run session garbage collection |
| `:PostCancel` | Cancel all active HTTP requests |

### Keymaps

| Mode | Key | Description |
|---|---|---|
| Normal | `<leader>pr` | Run HTTP request in buffer |
| Visual | `<leader>pr` | Run selected HTTP request |

### Environments

Create JSON files in `~/.config/nvim/post-nvim-envs/`:

```json
{
  "development": {
    "variables": {
      "base_url": "http://localhost:3000",
      "token": "dev-token-123"
    }
  },
  "production": {
    "variables": {
      "base_url": "https://api.example.com",
      "token": "prod-token-456"
    }
  }
}
```

## Implementation Status

- [x] Use treesitter to highlight request and responses (JSON, XML).
- [x] Define JSON schema to be used by the editor for request creation so that autocomplete will work.
- [x] Use `curl` via `vim.fn.jobstart()` to make async HTTP calls to various end points.
- [x] Allow configuration for proxy and certificate validation exceptions.
- [x] Persistent session object stored on file system, with configuration to delete the session object for any request.
- [x] Execution of a whole test suite (JSON).
- [x] Visual selection of request json and execution.
- [x] JSON Path based variable extraction and injection into templatized request.
