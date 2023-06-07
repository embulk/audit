# coding: utf-8
require 'octokit'
require 'minitest'
require 'yaml'

include Minitest::Assertions

class << self
  attr_accessor :assertions
end
self.assertions = 0

def assert_repos(expected_repos, actual_repos)
  expected_repo_names = expected_repos.map { |node| node[:name] }
  actual_repo_names = actual_repos.map { |node| node[:name] }
  assert_equal expected_repo_names, actual_repo_names
end

def load_expected_repos(repos_yaml)
  return File.open(repos_yaml) do |f|
    YAML.load(f, filename: repos_yaml, symbolize_names: true)
  end
end

def load_actual_repos(access_token)
  client = Octokit::Client.new(access_token: access_token)

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
  return response[:data][:organization][:repositories][:nodes]
end

expected_repos = load_expected_repos("repos.yaml")
actual_repos = load_actual_repos(ENV.fetch('GITHUB_TOKEN'))

assert_repos(expected_repos, actual_repos)
