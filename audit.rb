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

def sym_to_s(value)
  if value.is_a?(Hash)
    value.map { |k, v| [ k.to_s, sym_to_s(v) ] }.to_h
  elsif value.is_a?(Array)
    value.map { |e| sym_to_s(e) }
  elsif value.is_a?(Symbol)
    value.to_s
  else
    value
  end
end

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
  actual_repos.each do |actual_repo_name, actual_repo|
    assert { expected_repos[actual_repo_name] == actual_repo }
  end
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
        collaborators {
          totalCount
          nodes {
            login
          }
        }
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
    repositories[repository[:name]] = sym_to_s(repository)
  end
  return repositories
end

def dump_actual_repos(actual_repos, io)
  YAML.dump(actual_repos, io)
end

expected_repos = load_expected_repos("repos.yaml")
actual_repos = load_actual_repos(retrieve_github_token())

File.open("actual.yaml", "w") do |f|
  dump_actual_repos(actual_repos, f)
end

assert_repos(expected_repos, actual_repos)
