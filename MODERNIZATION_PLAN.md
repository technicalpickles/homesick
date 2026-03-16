# Homesick Modernization Plan

## Overview

Homesick is a Ruby CLI tool for managing dotfiles. The last gem release was in December 2017 (v1.1.6),
and several dependencies and tooling choices are now outdated. This document outlines a phased plan to
bring the project up to modern standards.

---

## Phase 1: Ruby and Dependency Updates

### 1.1 Drop Legacy Ruby Support

**Current**: Ruby 2.2.6 – 2.5.0
**Target**: Ruby 3.1+

- Remove conditional code branches for Ruby < 2.5 in `Gemfile`
- Update `.ruby-version` (if present) or add one targeting 3.1
- Remove `rack ~> 2.0.6` and `listen < 3` legacy shims in `Gemfile`
- Remove the `rb-readline ~> 0.5.0` legacy dependency

**Files**: `Gemfile`, `.travis.yml`

### 1.2 Update Runtime Dependency

**Current**: `thor >= 0.14.0`
**Target**: `thor ~> 1.3`

Thor 1.x introduced several breaking changes from 0.x. Validate that all CLI commands still work
correctly after upgrading, paying particular attention to:
- `say_status` signatures
- `no_tasks` vs `no_commands` (renamed in Thor 1.0)
- Method visibility and option handling

**Files**: `Gemfile`, `homesick.gemspec`, `lib/homesick/cli.rb`

### 1.3 Update Development Dependencies

| Gem | Current | Target |
|-----|---------|--------|
| `rspec` | `~> 3.5.0` | `~> 3.13` |
| `rubocop` | unpinned | `~> 1.70` |
| `guard` / `guard-rspec` | outdated | remove or update |
| `coveralls` | legacy | replace with `simplecov` |
| `jeweler` | outdated | remove (see Phase 2) |
| `terminal-notifier-guard` | `~> 1.7.0` | remove or update |
| `test_construct` | unpinned | verify compatibility |
| `capture-output` | `~> 1.0.0` | verify / replace with RSpec's built-in IO capture |

**Files**: `Gemfile`, `Rakefile`

---

## Phase 2: Replace Outdated Build Tooling

### 2.1 Remove Jeweler

Jeweler is a gem management tool from the early 2010s that is no longer actively maintained.
Modern Ruby gems use `bundler` and a hand-maintained or auto-generated gemspec.

**Actions**:
- Remove `jeweler` from `Gemfile` and `Rakefile`
- Rewrite `Rakefile` using plain Rake tasks + `bundler/gem_tasks`
- Manually maintain `homesick.gemspec` with proper metadata
- Remove generated fields (file lists) in favour of a `git ls-files` glob in the gemspec

**Files**: `Rakefile`, `Gemfile`, `homesick.gemspec`

### 2.2 Adopt StandardRB or Update RuboCop Config

- Replace the permissive `.rubocop.yml` exceptions with a modern, curated ruleset
- Consider adopting [`standardrb`](https://github.com/standardrb/standard) as an opinionated
  zero-config alternative to RuboCop, or update `.rubocop.yml` to current RuboCop defaults
- Address disabled rules one by one (see Phase 3 for `Eval`)

**Files**: `.rubocop.yml`, `Gemfile`

---

## Phase 3: Code Quality and Security

### 3.1 Eliminate `eval` in `.homesickrc` Execution

**Current** (`lib/homesick/cli.rb`):
```ruby
eval homesickrc.read, binding, homesickrc.expand_path.to_s
```

This executes arbitrary Ruby code from a user-controlled file with access to the CLI's `binding`,
creating a security risk and preventing RuboCop compliance.

**Proposed Alternatives** (pick one):
- **Option A – Restrict to DSL**: Define a limited DSL module and `instance_eval` the rc file
  against it, preventing access to internal state.
- **Option B – Remove feature**: Deprecate `.homesickrc` and document that users should use
  castle-level shell scripts instead. Add a deprecation warning in the current release.
- **Option C – Subprocess**: `load` the file in a subprocess so it cannot affect the parent process.

Recommended: **Option A** for maximum backward compatibility with a clear security boundary.

### 3.2 Address RuboCop Violations

Once Jeweler and `eval` are removed:
- Re-enable `Security/Eval`
- Re-enable `Metrics/ClassLength` and refactor `Homesick::CLI` (currently a large God class):
  - Extract subcommand groups (git ops, file ops, castle management) into separate Thor subcommands
    or helper objects
- Re-enable `Metrics/MethodLength` with a reasonable limit (15–20)
- Run `rubocop --auto-correct` for style-only offenses

**Files**: `.rubocop.yml`, `lib/homesick/cli.rb`, `lib/homesick/actions/`

### 3.3 Add Frozen String Literal Comments

Add `# frozen_string_literal: true` to all Ruby source files for performance and correctness.

---

## Phase 4: CI/CD Modernisation

### 4.1 Migrate from Travis CI to GitHub Actions

Travis CI's free tier for open-source projects has been significantly reduced. Replace `.travis.yml`
with a GitHub Actions workflow.

**Proposed workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby: ['3.1', '3.2', '3.3']
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      - run: bundle exec rake spec
      - run: bundle exec rubocop
```

**Files**: Remove `.travis.yml`, add `.github/workflows/ci.yml`

### 4.2 Add Dependabot for Automated Dependency Updates

Add `.github/dependabot.yml` to keep gem dependencies automatically updated via pull requests.

```yaml
version: 2
updates:
  - package-ecosystem: bundler
    directory: "/"
    schedule:
      interval: weekly
```

---

## Phase 5: Testing Improvements

### 5.1 Update and Expand Test Suite

- Upgrade from `rspec ~> 3.5.0` to `rspec ~> 3.13`
- Replace `coveralls` with `simplecov` for local coverage reporting
- Replace `capture-output` with RSpec's built-in `output` matcher where possible
- Review `spec/spec.opts` (deprecated; options should live in `.rspec`)
- Add tests for currently uncovered edge cases (e.g., `exec_all`, `open`, `generate`)
- Add integration tests that verify end-to-end dotfile linking

**Files**: `spec/`, `Gemfile`, `.rspec`

### 5.2 Add GitHub Actions Coverage Reporting

Integrate SimpleCov with a coverage badge (e.g., via Code Climate or Codecov) to replace the
defunct Coveralls badge in the README.

---

## Phase 6: Documentation and Release

### 6.1 Update README

- Update supported Ruby versions
- Remove references to Travis CI badge; add GitHub Actions badge
- Update Coveralls badge to new coverage provider
- Add a `CONTRIBUTING.md` with development setup instructions
- Clarify the security model of `.homesickrc`

### 6.2 Update ChangeLog

Document all modernization changes under a new version entry in `ChangeLog.markdown`.

### 6.3 Publish New Release

After all phases are complete:
- Bump version to `2.0.0` (major bump due to dropped Ruby < 3.1 support and Thor 1.x migration)
- Tag the release on GitHub
- Push updated gem to RubyGems.org

---

## Implementation Order

| Priority | Phase | Effort | Risk |
|----------|-------|--------|------|
| 1 | Phase 4 – GitHub Actions CI | Low | Low |
| 2 | Phase 4 – Dependabot | Very Low | Very Low |
| 3 | Phase 1 – Dependency updates | Medium | Medium |
| 4 | Phase 2 – Remove Jeweler | Medium | Low |
| 5 | Phase 3 – Security / eval fix | Medium | Medium |
| 6 | Phase 3 – RuboCop compliance | Medium | Low |
| 7 | Phase 5 – Test improvements | Medium | Low |
| 8 | Phase 6 – Docs + release | Low | Low |

---

## Files Changed Summary

| File | Action |
|------|--------|
| `Gemfile` | Remove legacy deps, update versions |
| `Rakefile` | Replace Jeweler with Bundler tasks |
| `homesick.gemspec` | Rewrite manually |
| `.rubocop.yml` | Update ruleset, re-enable disabled rules |
| `.travis.yml` | Delete |
| `.github/workflows/ci.yml` | Create (GitHub Actions) |
| `.github/dependabot.yml` | Create |
| `lib/homesick/cli.rb` | Fix eval, refactor large methods |
| `lib/homesick/**/*.rb` | Add frozen_string_literal |
| `spec/` | Upgrade RSpec, expand coverage |
| `README.markdown` | Update badges, Ruby versions, security note |
| `ChangeLog.markdown` | Add new entries |
