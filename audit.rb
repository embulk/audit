# coding: utf-8
require 'octokit'
require 'minitest'
require 'pathname'
require 'yaml'

SCRIPT_PATH = Pathname.new(__dir__)

include Minitest::Assertions

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
actual_repos = load_actual_repos(retrieve_github_token())

puts actual_repos.inspect

# assert_repos(expected_repos, actual_repos)
