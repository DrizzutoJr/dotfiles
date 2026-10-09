---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
user-invocable: true
---

When explaining code:

1. **Start with an analogy**: Compare the code to something from everyday life (restaurant kitchen, assembly line, library system, etc.)

2. **Draw a diagram** (when helpful): Use ASCII art for:
   - Data flow between components
   - State machines or lifecycle
   - Class/module relationships
   - Request/response cycles
   Skip diagrams for simple functions or self-explanatory code.

3. **Walk through the code**: Explain step-by-step what happens, focusing on *why* not just *what*

4. **Highlight gotchas**: Common mistakes, edge cases, or misconceptions

Keep explanations conversational. Match depth to complexity—a utility function needs less than a state management system.

If no specific code is provided, offer numbered options:

> What would you like me to explain?
> 1. A specific file (tell me which one)
> 2. A specific function or class (tell me the name)
> 3. Overview of the repo's architecture

The user can reply with just a number.
