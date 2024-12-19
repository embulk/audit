# coding: utf-8
require 'octokit'
require 'minitest'
require 'minitest/power_assert'
require 'pathname'
require 'yaml'

SCRIPT_PATH = Pathname.new(__dir__)

include Minitest::Assertions
include Minitest::PowerAssert::Assertions

class << self
  attr_accessor :assertions
end
self.assertions = 0

def retrieve_github_token()
  token_path = SCRIPT_PATH.join('github_token')
  if File.exist?(token_path)
    File.open(token_path) do |f|
      puts "Found GitHub token file: github_token"
      return f.gets
    end
  end

  if ENV.has_key?('GITHUB_TOKEN')
    puts "Not found GitHub token file. Using the env: GITHUB_TOKEN"
    return ENV.fetch('GITHUB_TOKEN')
  end

  raise StandardError, "Not found GitHub token token."
end

def assert_repos(expected_repos, actual_repos)
  assert { expected_repos == actual_repos }
end

def load_expected_repos(repos_yaml)
  return File.open(repos_yaml) do |f|
    YAML.load(f, filename: repos_yaml, symbolize_names: false)
  end
end

def load_actual_repos(access_token)
  client = Octokit::Client.new(access_token: access_token)

  query = <<-GRAPHQL
query paginate($cursor: String) {
  organization(login: "embulk") {
    repositories(visibility: PUBLIC, first: 100, orderBy: {field: NAME, direction: ASC}, after: $cursor) {
      nodes {
        name
        visibility
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
GRAPHQL

  response_sawyer = client.post '/graphql', { query: query }.to_json
  repositories_array = response_sawyer.data.to_h[:organization][:repositories][:nodes]
  repositories = {}
  repositories_array.each do |repository|
    repositories[repository[:name]] = {}
  end
  return repositories
end

expected_repos = load_expected_repos("repos.yaml")
actual_repos = load_actual_repos(retrieve_github_token())

assert_repos(expected_repos, actual_repos)
