"""
title: Meilisearch Documentation Search
author: AI Tool Server Stack
version: 1.0.0
description: Search indexed documentation and websites using Meilisearch
required_open_webui_version: 0.3.0
"""

import requests
from typing import Callable, Any
from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        MEILISEARCH_URL: str = Field(
            default="http://meilisearch:7700",
            description="Meilisearch instance URL"
        )
        MEILISEARCH_API_KEY: str = Field(
            default="",
            description="Meilisearch API key (Master Key)"
        )
        MEILISEARCH_INDEX: str = Field(
            default="web_docs",
            description="Index name to search"
        )
        RESULTS_LIMIT: int = Field(
            default=5,
            description="Number of results to return"
        )

    def __init__(self):
        self.valves = self.Valves()

    def search_docs(
        self,
        query: str,
        __event_emitter__: Callable[[dict], Any] = None
    ) -> str:
        """
        Search indexed documentation using Meilisearch.
        Use this tool when users ask questions about:
        - Open WebUI documentation
        - Anthropic/Claude documentation
        - OpenAI documentation
        - Meilisearch documentation
        - Any other indexed documentation

        :param query: The search query string
        :return: Formatted search results with titles, URLs, and content snippets
        """

        if __event_emitter__:
            __event_emitter__(
                {
                    "type": "status",
                    "data": {
                        "description": f"Searching indexed docs for: {query}",
                        "done": False
                    }
                }
            )

        try:
            # Prepare search request
            search_url = f"{self.valves.MEILISEARCH_URL}/indexes/{self.valves.MEILISEARCH_INDEX}/search"
            headers = {}
            if self.valves.MEILISEARCH_API_KEY:
                headers["Authorization"] = f"Bearer {self.valves.MEILISEARCH_API_KEY}"

            payload = {
                "q": query,
                "limit": self.valves.RESULTS_LIMIT,
                "attributesToHighlight": ["content"],
                "attributesToCrop": ["content"],
                "cropLength": 200,
                "highlightPreTag": "**",
                "highlightPostTag": "**"
            }

            # Execute search
            response = requests.post(search_url, json=payload, headers=headers, timeout=10)
            response.raise_for_status()
            results = response.json()

            if __event_emitter__:
                __event_emitter__(
                    {
                        "type": "status",
                        "data": {
                            "description": f"Found {len(results.get('hits', []))} results",
                            "done": True
                        }
                    }
                }
            )

            # Format results
            if not results.get("hits"):
                return "No results found in the indexed documentation."

            formatted_results = []
            for i, hit in enumerate(results["hits"], 1):
                title = hit.get("hierarchy", {}).get("lvl0", hit.get("url", "Untitled"))
                url = hit.get("url", "")
                content = hit.get("_formatted", {}).get("content", hit.get("content", ""))

                formatted_results.append(
                    f"**Result {i}:** {title}\n"
                    f"**URL:** {url}\n"
                    f"**Content:** {content}\n"
                )

            return "\n\n".join(formatted_results)

        except requests.exceptions.RequestException as e:
            error_msg = f"Error searching Meilisearch: {str(e)}"
            if __event_emitter__:
                __event_emitter__(
                    {
                        "type": "status",
                        "data": {
                            "description": error_msg,
                            "done": True
                        }
                    }
                )
            return error_msg
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            if __event_emitter__:
                __event_emitter__(
                    {
                        "type": "status",
                        "data": {
                            "description": error_msg,
                            "done": True
                        }
                    }
                }
            return error_msg
