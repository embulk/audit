# coding: utf-8
require 'octokit'

client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN'))

query = <<-GRAPHQL
query paginate($cursor: String) {
  organization(login: "embulk") {
    repositories(first: 100, orderBy: {field: NAME, direction: ASC}, after: $cursor) {
      nodes {
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
GRAPHQL

response = client.post '/graphql', { query: query }.to_json
response[:data][:organization][:repositories][:nodes].each do |repo|
  puts repo.attrs
end
