from fastmcp import Client
from fastmcp.client.transports import SSETransport
import asyncio
import httpx

def httpx_client_factory(**kw):
    return httpx.AsyncClient(verify=False, trust_env=False, **kw) 

transport = SSETransport(url="http://127.0.0.1:18881/sse", httpx_client_factory=httpx_client_factory)
client = Client(transport)

async def main():
    async with client:
        tools = await client.list_tools()
        print(f"Available tools: {tools}")
        for i in range(3):
            result = await client.call_tool("add", {"a": 5, "b": i})
            print(result[0].text) 
            await asyncio.sleep(1)
        for i in range(3):
            result = await client.call_tool("add2", {"a": 5, "b": i})
            print(result[0].text) 
            await asyncio.sleep(1)
        for i in range(3):
            result = await client.call_tool("add3", {"a": 5, "b": i})
            print(result[0].text) 
            await asyncio.sleep(1)

if __name__ == '__main__':
    asyncio.run(main())