# Security Policy

This document outlines the security policies and procedures for the Prometheus Development Environment project.

## Table of Contents

- [Supported Versions](#supported-versions)
- [Security Best Practices](#security-best-practices)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [Security Features](#security-features)
- [Credential Management](#credential-management)
- [Network Security](#network-security)
- [Container Security](#container-security)
- [Incident Response](#incident-response)

## Supported Versions

We actively maintain security updates for the following versions:

| Version | Supported          | Notes                        |
| ------- | ------------------ | ---------------------------- |
| 1.x     | :white_check_mark: | Current release              |
| 0.x     | :x:                | Development versions         |

Component versions:
- Prometheus: 2.47.0+
- Node Exporter: 1.7.0+
- Nginx: Latest Alpine
- Base OS: Alpine Linux (containers)

## Security Best Practices

### For Users

1. **Never commit credentials**
   ```bash
   # Always check before committing
   git status
   git diff --cached
   ```

2. **Use strong passwords**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

3. **Rotate credentials regularly**
   - Change passwords every 90 days
   - Rotate API tokens periodically
   - Update after any suspected compromise

4. **Limit network exposure**
   ```bash
   # Use localhost binding for development
   ports:
     - "127.0.0.1:9090:9090"
   ```

5. **Keep components updated**
   ```bash
   # Pull latest images
   podman pull docker.io/prom/prometheus:latest
   ```

### For Administrators

1. **Enable authentication** for any non-local deployment
2. **Use HTTPS** in production (add TLS termination)
3. **Implement rate limiting** to prevent abuse
4. **Monitor access logs** for suspicious activity
5. **Regular security audits** of configurations

## Security Features

### Authentication Methods

1. **Basic Authentication**
   - HTTPAuth via Nginx
   - Stored in `.htpasswd` file
   - Bcrypt password hashing

2. **Bearer Token**
   - Header-based authentication
   - Suitable for API access
   - Stateless authentication

3. **API Token**
   - Custom header validation
   - Application-specific tokens
   - Easy integration

### Rate Limiting

```nginx
# Default configuration
limit_req_zone $binary_remote_addr zone=prometheus_limit:10m rate=30r/s;
limit_req zone=prometheus_limit burst=50 nodelay;
```

### Security Headers

```nginx
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

## Credential Management

### Storage Guidelines

1. **Development Environment**
   ```bash
   # Use environment file
   configs/credentials.env
   
   # Set proper permissions
   chmod 600 configs/credentials.env
   ```

2. **Production Environment**
   - Use secrets management system (Vault, Kubernetes Secrets)
   - Never store in code or images
   - Implement key rotation

### Password Requirements

- Minimum 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- No dictionary words
- Unique per service

### Token Management

- Generate cryptographically secure tokens
- Set expiration where possible
- Log token usage
- Revoke compromised tokens immediately

## Network Security

### Firewall Configuration

```bash
# Recommended firewall rules
firewall-cmd --add-port=9090/tcp --zone=internal --permanent
firewall-cmd --remove-port=9090/tcp --zone=public --permanent
firewall-cmd --reload
```

### Network Isolation

```yaml
networks:
  monitoring:
    internal: true  # For production
    driver: bridge
    ipam:
      config:
        - subnet: 172.26.0.0/24
```

### TLS Configuration (Production)

```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}
```

## Container Security

### Image Security

1. **Use specific tags**
   ```yaml
   # Good
   image: docker.io/prom/prometheus:v2.47.0
   
   # Avoid
   image: prometheus:latest
   ```

2. **Scan images regularly**
   ```bash
   # Using Trivy
   trivy image docker.io/prom/prometheus:v2.47.0
   ```

3. **Minimize attack surface**
   - Use Alpine-based images
   - Don't install unnecessary packages
   - Run as non-root user

### Runtime Security

```yaml
security_opt:
  - no-new-privileges:true
  - seccomp:unconfined
read_only: true
user: nobody
```

### Volume Security

- Mount as read-only where possible
- Limit volume access
- Don't mount sensitive host paths

## Incident Response

### If Credentials Are Compromised

1. **Immediate Actions**
   - Change all passwords
   - Rotate all tokens
   - Review access logs

2. **Investigation**
   - Check container logs
   - Review authentication attempts
   - Identify breach timeline

3. **Remediation**
   - Update configurations
   - Patch vulnerabilities
   - Enhance monitoring

### Security Checklist

#### Before Deployment
- [ ] Credentials file created and secured
- [ ] Strong passwords generated
- [ ] Authentication enabled
- [ ] Network properly configured
- [ ] Firewall rules applied

#### Regular Maintenance
- [ ] Update container images
- [ ] Rotate credentials
- [ ] Review access logs
- [ ] Check for CVEs
- [ ] Test backup procedures

## Security Tools

### Recommended Tools

1. **Secret Scanning**
   ```bash
   # GitLeaks
   gitleaks detect --source .
   ```

2. **Dependency Scanning**
   ```bash
   # Safety (Python)
   safety check -r scripts/requirements.txt
   ```

3. **Container Scanning**
   ```bash
   # Clair, Trivy, or Anchore
   ```

## Compliance

This project aims to follow:
- OWASP Security Best Practices
- CIS Container Benchmarks
- NIST Cybersecurity Framework

For general questions:
- GitHub Issues (non-security)
- Discussions forum

## Acknowledgments

We thank the security researchers who help keep this project secure through responsible disclosure.
