from first_time_contribution_tagger import PullRequest


def test_filterGraphqlOutput():
    input = {
        "number": 10,
        "author": {"login": "some-valid-github-user-name"},
        "labels": {"nodes": [{"name": " 0.kind: bug "}]},
    }
    expectd = PullRequest(number=10, author="some-valid-github-user-name", labels=[" 0.kind: bug "])
    test = PullRequest.filterGraphqlOutput(input)
    assert test.number == expectd.number
    assert test.author == expectd.author
    assert test.labels == expectd.labels
