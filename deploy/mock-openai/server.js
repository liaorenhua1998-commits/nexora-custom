const http = require("http");

const PORT = Number(process.env.MOCK_OPENAI_PORT || 8090);
const API_KEY = process.env.MOCK_OPENAI_API_KEY || "mock-upstream-secret";

function sendJson(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
    });
    req.on("end", () => {
      if (!raw.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (err) {
        reject(err);
      }
    });
    req.on("error", reject);
  });
}

function unauthorized(res) {
  sendJson(res, 401, {
    error: {
      message: "Invalid mock upstream API key",
      type: "invalid_request_error",
    },
  });
}

function ensureAuth(req, res) {
  const auth = req.headers.authorization || "";
  if (auth !== `Bearer ${API_KEY}`) {
    unauthorized(res);
    return false;
  }
  return true;
}

function getPromptText(body) {
  if (Array.isArray(body.messages) && body.messages.length > 0) {
    const last = body.messages[body.messages.length - 1];
    if (typeof last?.content === "string") {
      return last.content;
    }
  }
  if (Array.isArray(body.input) && body.input.length > 0) {
    const last = body.input[body.input.length - 1];
    if (Array.isArray(last?.content) && last.content.length > 0) {
      const part = last.content.find((item) => item && typeof item.text === "string");
      if (part) {
        return part.text;
      }
    }
  }
  return "hi";
}

function writeResponsesStream(res, model, text) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  const usage = {
    input_tokens: 8,
    output_tokens: 12,
    total_tokens: 20,
  };
  const events = [
    { type: "response.created", response: { id: "resp_mock_1", model, status: "in_progress" } },
    { type: "response.output_text.delta", delta: text },
    {
      type: "response.completed",
      response: {
        id: "resp_mock_1",
        object: "response",
        model,
        status: "completed",
        output: [
          {
            type: "message",
            role: "assistant",
            content: [{ type: "output_text", text }],
          },
        ],
        usage,
      },
    },
  ];
  for (const event of events) {
    res.write(`data: ${JSON.stringify(event)}\n\n`);
  }
  res.end();
}

function writeChatCompletionsStream(res, model, text) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  const usage = {
    prompt_tokens: 9,
    completion_tokens: 14,
    total_tokens: 23,
  };
  const chunks = [
    {
      id: "chatcmpl_mock_1",
      object: "chat.completion.chunk",
      model,
      choices: [{ index: 0, delta: { role: "assistant", content: "" } }],
    },
    {
      id: "chatcmpl_mock_1",
      object: "chat.completion.chunk",
      model,
      choices: [{ index: 0, delta: { content: text } }],
    },
    {
      id: "chatcmpl_mock_1",
      object: "chat.completion.chunk",
      model,
      choices: [{ index: 0, delta: {}, finish_reason: "stop" }],
    },
    {
      id: "chatcmpl_mock_1",
      object: "chat.completion.chunk",
      model,
      choices: [],
      usage,
    },
  ];
  for (const chunk of chunks) {
    res.write(`data: ${JSON.stringify(chunk)}\n\n`);
  }
  res.write("data: [DONE]\n\n");
  res.end();
}

const server = http.createServer(async (req, res) => {
  if (req.url === "/health") {
    sendJson(res, 200, { status: "ok" });
    return;
  }

  if (req.url === "/v1/models" && req.method === "GET") {
    if (!ensureAuth(req, res)) {
      return;
    }
    sendJson(res, 200, {
      object: "list",
      data: [
        { id: "gpt-4.1-mini", object: "model", owned_by: "nexora-mock" },
        { id: "gpt-4o-mini", object: "model", owned_by: "nexora-mock" },
      ],
    });
    return;
  }

  if (req.url === "/v1/responses" && req.method === "POST") {
    if (!ensureAuth(req, res)) {
      return;
    }
    const body = await readJson(req).catch(() => null);
    if (!body) {
      sendJson(res, 400, { error: { message: "Invalid JSON", type: "invalid_request_error" } });
      return;
    }
    const model = body.model || "gpt-4.1-mini";
    const text = `Mock response from ${model}: ${getPromptText(body)}`;
    if (body.stream) {
      writeResponsesStream(res, model, text);
      return;
    }
    sendJson(res, 200, {
      id: "resp_mock_1",
      object: "response",
      model,
      output_text: text,
      output: [
        {
          type: "message",
          role: "assistant",
          content: [{ type: "output_text", text }],
        },
      ],
      usage: {
        input_tokens: 8,
        output_tokens: 12,
        total_tokens: 20,
      },
    });
    return;
  }

  if (req.url === "/v1/chat/completions" && req.method === "POST") {
    if (!ensureAuth(req, res)) {
      return;
    }
    const body = await readJson(req).catch(() => null);
    if (!body) {
      sendJson(res, 400, { error: { message: "Invalid JSON", type: "invalid_request_error" } });
      return;
    }
    const model = body.model || "gpt-4.1-mini";
    const text = `Mock chat completion from ${model}: ${getPromptText(body)}`;
    if (body.stream) {
      writeChatCompletionsStream(res, model, text);
      return;
    }
    sendJson(res, 200, {
      id: "chatcmpl_mock_1",
      object: "chat.completion",
      model,
      choices: [
        {
          index: 0,
          finish_reason: "stop",
          message: {
            role: "assistant",
            content: text,
          },
        },
      ],
      usage: {
        prompt_tokens: 9,
        completion_tokens: 14,
        total_tokens: 23,
      },
    });
    return;
  }

  sendJson(res, 404, { error: { message: "Not found", type: "invalid_request_error" } });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`mock-openai listening on ${PORT}`);
});
