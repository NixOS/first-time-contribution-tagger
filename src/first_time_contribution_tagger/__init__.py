import os
import pickle

from first_time_contribution_tagger.pullRequest import PullRequest


class Settings:
    def __init__(self) -> None:
        self.githubToken = os.getenv("FIRST_TIME_CONTRIBUTION_GITHUB_TOKEN")
        if self.githubToken is None:
            exit("ERROR: githubToken not set. Please set the FIRST_TIME_CONTRIBUTION_GITHUB_TOKEN env var")
        self.org = os.getenv("FIRST_TIME_CONTRIBUTION_ORG")
        if self.org is None:
            exit("ERROR: org not set. Please set the FIRST_TIME_CONTRIBUTION_GITHUB_ORG env var")
        self.repo = os.getenv("FIRST_TIME_CONTRIBUTION_REPO")
        if self.repo is None:
            exit("ERROR: repo not set. Please set the FIRST_TIME_CONTRIBUTION_GITHUB_REPO env var")
        self.label = os.getenv("FIRST_TIME_CONTRIBUTION_LABEL")
        if self.label is None:
            exit("ERROR: label not set. Please set the FIRST_TIME_CONTRIBUTION_GITHUB_LABEL env var")
        self.cache = os.getenv("FIRST_TIME_CONTRIBUTION_CACHE")
        if self.cache is None:
            print("WARNING: Caching is disabled. To use a cache set the FIRST_TIME_CONTRIBUTION_CACHE env var")
        # self.logLevel = os.environ["FIRST_TIME_CONTRIBUTION_LOG_LEVEL"]


class FirstTimeContributionTagger:
    def __init__(self, settings):
        self.prs: list["PullRequest"] = []
        self.knownAuthors = []
        self.latestPr: int = 1
        self.settings: "Settings" = settings

    def loadCache(self):
        if os.path.isdir(self.settings.cache):
            # Load chached PRs
            cached_prs = f"{self.settings.cache}/prs.pickle"
            if os.path.isfile(cached_prs):
                with open(cached_prs, "rb") as file:
                    self.prs: list[PullRequest] = pickle.load(file)
                self.latestPr = self.prs[-1].number
                # ToDo convert to loggin
                print("DEBUG: cached prs loaded successfully")
            else:
                # ToDo convert to loggin
                print("DEBUG: no cached prs loaded, file not found")
            # Load chached authors
            cached_authors = f"{self.settings.cache}/authors.pickle"
            if os.path.isfile(cached_authors):
                with open(cached_authors, "rb") as file:
                    self.knownAuthors: list[str] = pickle.load(file)
                # ToDo convert to loggin
                print("DEBUG: cached authors loaded successfully")
            else:
                # ToDo convert to loggin
                print("DEBUG: no cached authors loaded, file not found")
        else:
            # ToDo convert to loggin
            print("DEBUG: no cache loaded, folder not found")

    def saveCache(self):
        # ToDo add logging
        if not os.path.exists(self.settings.cache):
            os.makedirs(self.settings.cache)
        # Save PRs
        with open(f"{self.settings.cache}/prs.pickle", "wb") as file:
            pickle.dump(self.prs, file)
        # Save knownAuthors
        with open(f"{self.settings.cache}/authors.pickle", "wb") as file:
            pickle.dump(self.knownAuthors, file)
        print("DEBUG: CACHE SAVED")

    def addToNewPRs(self, org, repo, label, githubToken):
        labelsNeeded: list[PullRequest] = []
        # Just a sanity check :D
        if len(self.knownAuthors) < 2500:
            labelsNeeded = self.prs
        else:
            # for every pr in a reversed list to search top to bottom
            for pr in self.prs[::-1]:
                # if the pr is a newer one
                if pr.number > self.latestPr:
                    labelsNeeded.append(pr)
                else:
                    break
            # reverse back to tag old prs first and don't fuck up new contribs that opend two prs
            labelsNeeded[::-1]
        # now add labels to the new prs
        for pr in labelsNeeded:
            if pr.author not in self.knownAuthors:
                self.knownAuthors.append(pr.author)
                PullRequest.addLabel(org, repo, pr.number, label, githubToken)
            else:
                print(f"pr_number: {pr.number}, no label added")


def main():
    settings = Settings()
    ftc = FirstTimeContributionTagger(settings)
    if settings.cache is not None:
        ftc.loadCache()
    ftc.prs += PullRequest.getNewPRs(
        latest_pr=ftc.latestPr, githubToken=settings.githubToken, org=settings.org, repo=settings.repo
    )
    ftc.addToNewPRs(settings.org, settings.repo, settings.label, settings.githubToken)
    if settings.cache is not None:
        ftc.saveCache()


if __name__ == "__main__":
    main()
