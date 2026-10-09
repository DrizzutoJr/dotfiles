---
name: explain-code
description: Explain how code works by tracing the relevant implementation, citing file locations, and clarifying data flow or behavior with a diagram when useful.
user-invocable: true
---

Explain the code the user points to, or the behavior they ask about. If the target is unclear, ask for a file, symbol, behavior, or architecture overview.

Inspect the relevant source before explaining it. Trace the path from its entry point through important calls, inputs, outputs, and state changes. Follow related code only as far as needed to answer the question.

Lead with a short description of what the code does. Then walk through the path in execution order and explain why the important steps matter. Cite file and line locations for claims about the implementation. Separate behavior visible in the code from runtime behavior or intent you infer.

Use a compact diagram, concrete example, or everyday analogy when it makes a complex flow easier to understand. Point out gotchas supported by the code. Match the depth to the user's question and the complexity of the code.
