from typing import Any

import requests


class PullRequest:
    def __init__(self, number: int, author: str | None, labels: list[str]) -> None:
        self.number: int = number
        self.author: str | None = author
        self.labels: list[str] = labels

    @staticmethod
    def filterGraphqlOutput(request_data: Any) -> "PullRequest":
        number = request_data["number"]
        if request_data["author"] is not None:
            author = request_data["author"]["login"]
        else:
            author = None
        labels = []
        if request_data["labels"]["nodes"] != []:
            for label in request_data["labels"]["nodes"]:
                labels.append(label["name"])
        return PullRequest(number=number, author=author, labels=labels)

    @staticmethod
    def graphqlQuery(body: str, githubToken: str) -> requests.models.Response:
        # ToDo add error handling for:
        # {'errors': [{'type': 'RATE_LIMITED', 'message': 'API rate limit exceeded for user ID 00000000.'}]}
        url = "https://api.github.com/graphql"
        header = {"Authorization": f"Bearer {githubToken}"}
        req = requests.post(url, headers=header, json={"query": body})
        # ToDO: Add logign
        # req.status_code
        # req.json()
        # print(
        # f"status: {req.status_code}, number: {req.json()['data']['repository']['pullRequests']['nodes'][0]['
        # number']}, page:{req.json()['data']['repository']['pullRequests']['pageInfo']['endCursor']}"
        # )
        return req

    @classmethod
    def getSpecificPR(cls, org: str, repo: str, prNumber: int, githubToken: str) -> "PullRequest":
        body = f"""
        {{
          repository(owner: "{org}", name: "{repo}") {{
            pullRequest(number: {prNumber}) {{
              number
              author {{
                login
              }}
              labels(first: 100) {{
                nodes {{
                  name
                }}
              }}
            }}
          }}
        }}
        """
        req = cls.graphqlQuery(body, githubToken)
        return cls.filterGraphqlOutput(req.json()["data"]["repository"]["pullRequest"])

    @classmethod
    def getNewPRs(cls, org: str, repo: str, latest_pr: int, githubToken: str) -> list["PullRequest"]:
        print("DEBUG: getting new PRs")
        new_prs = []
        new_pr = 0
        page = ""
        while latest_pr < new_pr or new_pr == 0:
            body = f"""
                query Query {{
                  repository(owner: "{org}", name: "{repo}") {{
                    pullRequests(
                      {page}
                      first: 100
                      orderBy: {{field: CREATED_AT, direction: DESC}}
                    )
                    {{
                      pageInfo {{
                        hasNextPage
                        endCursor
                      }}
                      nodes {{
                        number
                        author {{
                          login
                        }}
                        labels(first: 100) {{
                          nodes {{
                            name
                          }}
                        }}
                      }}
                    }}
                  }}
                }}
            """
            req = cls.graphqlQuery(body, githubToken)
            if req.json()["data"]["repository"]["pullRequests"]["pageInfo"]["hasNextPage"]:
                for pr in req.json()["data"]["repository"]["pullRequests"]["nodes"]:
                    filterd_output = cls.filterGraphqlOutput(pr)
                    new_pr = filterd_output.number
                    new_prs.append(filterd_output)
                page = f"after: \"{req.json()['data']['repository']['pullRequests']['pageInfo']['endCursor']}\""
                print(f"getting new prs: {new_pr}")
            else:
                return new_prs[::-1]
        return new_prs[::-1]

    @classmethod
    def addLabel(cls, org: str, repo: str, prNumber: int, label: str, githubToken: str) -> "PullRequest":
        url = f"https://api.github.com/repos/NixOS/nixpkgs/issues/{prNumber}/labels"
        header: dict[str, str] = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {githubToken}",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        pr = cls.getSpecificPR(org, repo, prNumber, githubToken)
        if label not in pr.labels:
            data = {"labels": pr.labels + [label]}
            req = requests.post(url, headers=header, json=data)
            labels: list[str] = []
            for _label in req.json():
                labels.append(_label["name"])
            pr.labels = labels
            # ToDO: Add logign
            # req.status_code
            # req.json()
            print(f"pr_number: {pr.number}, label added")
        else:
            print(f"pr_number: {pr.number}, no label added")
        return pr
