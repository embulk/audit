Audit GitHub repositories automatically, especially about security-related matters, such as :

* Permitted users, and their permissions
* Permissions for GitHub Actions, such as approval needed for all / first-time contributors (to be implemented)
* Secrets and Variables (to be implemented)
* ...

This just compares the current repository configurations retrieved from GitHub API with `repos.yaml`, which contains their "expected" configurations.

How to run audit
=================

Create a GitHub fine-grained personal access token at : https://github.com/settings/personal-access-tokens/new

* Resource owner: embulk
* Expiration: as needed
* Repository access: All repositories
* Permissions:
    * Repository permissions:
        * Administration: Read-only
        * Commit statuses: Read-only
        * Contents: Read-only
        * Custom properties: Read-only
        * Environments: Read-only
        * Metadata: Read-only (mandatory)
        * Pull requests: Read-only

```
bundle install
```

```
# Or, it loads GitHub Token from the "GITHUB_TOKEN` environment variable if the file does not exist.
echo "..." > github_token
```

```
bundle exec ruby ./audit.rb
```
