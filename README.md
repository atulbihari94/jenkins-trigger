# Jenkins Trigger

A sample project to demonstrate Jenkins CI/CD pipeline triggered via GitHub webhooks.

## Project Structure

```
jenkins-trigger/
├── one/
│   ├── app.py          # Sample Python application
│   └── config.json     # App configuration
├── two/
│   ├── server.py       # Simple HTTP server
│   └── utils.py        # Utility functions
├── Jenkinsfile         # Jenkins pipeline definition
└── README.md
```

## Branches

- `main` - Production-ready code
- `develop` - Development branch
- `qa-devops` - QA and DevOps testing
- `test` - Testing branch

## Jenkins Webhook Setup

See the webhook configuration guide in the repository wiki or refer to inline comments in the Jenkinsfile.
