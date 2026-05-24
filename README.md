# SK Interview

Interview-focused technical reference with deep Q&A for every concept. Complete knowledge per topic - zero to mastery - without needing other sources.

Built with [Just the Docs](https://just-the-docs.com/) (Jekyll) following the **Interview Mastery Dictionary v1.0** spec (8 sections per keyword, keyword-batch generation, BAD-before-GOOD code examples, masterclass-level depth).

## Quick start

```pwsh
# 1. Install Ruby gems
bundle install

# 2. Serve locally with live reload
bundle exec jekyll serve

# 3. Build static site
bundle exec jekyll build

# 4. Enable git hooks (one-time per clone)
git config core.hooksPath .githooks
```

## Layout

```
southstar/
  _config.yml         Jekyll/just-the-docs config
  Gemfile             Ruby dependencies
  docs/               Published content (homepage + topic folders)
  spec/               Generation spec, topic registry, contributor guide
  scripts/            Scaffold + content-generation automation
  .github/            Copilot agents, instructions, prompts, CI workflows
  .githooks/          Local git hooks (enable via core.hooksPath)
  .vscode/            Editor settings + recommended extensions
```

## Generating content

Open the workspace in VS Code with the GitHub Copilot Chat extension and use:

- `/interview` - full agent for new topics, new subtopics, gap-filling
- `@scaffold` - run the scaffold generator for a topic
- `@generate-entries` - generate keyword content in batches
- `@fill-content` - fill stubs in existing files

See [spec/interview_content_generator.md](spec/interview_content_generator.md) for the full v1.0 generation specification and [spec/topics_registry.md](spec/topics_registry.md) for the topic registry.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
