import asyncio
import anthropic
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

async def main():
    client = anthropic.Anthropic()

    print("Gravitino + Trino MCP App")
    print("Ask questions about your data. Type 'quit' to exit.\n")

    headers = {"Accept": "application/json, text/event-stream"}

    async with streamablehttp_client("http://127.0.0.1:8001/mcp/", headers=headers) as (gr, gw, _):
        async with streamablehttp_client("http://127.0.0.1:8002/mcp", headers=headers) as (mr, mw, _):
            async with ClientSession(gr, gw) as gravitino:
                async with ClientSession(mr, mw) as trino:

                    await gravitino.initialize()
                    await trino.initialize()

                    g_tools = await gravitino.list_tools()
                    m_tools = await trino.list_tools()

                    all_tools = []
                    for tool in g_tools.tools:
                        all_tools.append({
                            "name": f"gravitino_{tool.name}",
                            "description": tool.description,
                            "input_schema": tool.inputSchema
                        })
                    for tool in m_tools.tools:
                        all_tools.append({
                            "name": f"trino_{tool.name}",
                            "description": tool.description,
                            "input_schema": tool.inputSchema
                        })

                    history = []

                    while True:
                        user_input = input("Question: ")
                        if user_input.lower() == 'quit':
                            break

                        history.append({"role": "user", "content": user_input})

                        while True:
                            response = client.messages.create(
                                model="claude-sonnet-4-20250514",
                                max_tokens=4096,
                                tools=all_tools,
                                messages=history
                            )

                            if response.stop_reason == "end_turn":
                                answer = next(b.text for b in response.content if hasattr(b, 'text'))
                                history.append({"role": "assistant", "content": response.content})
                                print(f"\nClaude: {answer}\n")
                                break

                            if response.stop_reason == "tool_use":
                                history.append({"role": "assistant", "content": response.content})
                                tool_results = []

                                for block in response.content:
                                    if block.type == "tool_use":
                                        tool_name = block.name
                                        tool_input = block.input

                                        print(f"  [calling {tool_name}...]")

                                        if tool_name.startswith("gravitino_"):
                                            actual_name = tool_name[len("gravitino_"):]
                                            result = await gravitino.call_tool(actual_name, tool_input)
                                        else:
                                            actual_name = tool_name[len("trino_"):]
                                            result = await trino.call_tool(actual_name, tool_input)

                                        tool_results.append({
                                            "type": "tool_result",
                                            "tool_use_id": block.id,
                                            "content": str(result.content)
                                        })

                                history.append({"role": "user", "content": tool_results})

asyncio.run(main())
