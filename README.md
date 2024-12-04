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
env GITHUB_TOKEN="..." bundle exec ruby ./audit.rb
```
