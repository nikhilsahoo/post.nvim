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

## To Dos:
- [ ] Use treesitter to highlight request and responses (JSON, XML).
- [ ] Define JSON schema to be used by the editor for request creation so that autocomplete will work.
- [ ] Use `Curl` lua module to make http calls to various end points.
- [ ] Allow configuration for proxy and certificate validation exceptions.
- [ ] Persistent session object stored on file system, with configuration to delete the session object for any request.
- [ ] Execution of a whole test suite (JSON).
- [ ] Visual selection of request json and execution.
- [ ] JSON Path based variable extraction and injection into templatized request.
